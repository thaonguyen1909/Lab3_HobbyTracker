import { randomUUID } from 'node:crypto';
import { FieldPath, FieldValue, Timestamp, type Firestore, type DocumentReference } from 'firebase-admin/firestore';
import { cleanupObjectPath, type CleanupMedia, type CleanupObject } from './moment_cleanup_media.js';

export const CLEANUP_GRACE_MS = 5 * 60_000;
export const ORPHAN_AGE_MS = 24 * 60 * 60_000;
export const OUTBOX_RETENTION_MS = ORPHAN_AGE_MS;
const PAGE = 10;
type Summary = { busy: boolean; moments: number; uploads: number; inbox: number; outboxes: number; objects: number; errors: number };

export class MomentCleanup {
  constructor(private readonly db: Firestore, private readonly media: CleanupMedia,
    private readonly now: () => number = Date.now) {}
  async run(): Promise<Summary> {
    const result: Summary = { busy: false, moments: 0, uploads: 0, inbox: 0, outboxes: 0, objects: 0, errors: 0 };
    const control = this.db.doc('momentMaintenance/cleanup'), lease = randomUUID();
    const locked = await this.db.runTransaction(async tx => {
      const snap = await tx.get(control);
      if ((snap.data()?.leaseUntil?.toMillis() ?? 0) > this.now()) return false;
      tx.set(control, { lease, leaseUntil: Timestamp.fromMillis(this.now() + 150_000) }, { merge: true }); return true;
    });
    if (!locked) return { ...result, busy: true };
    try {
      await this.backfill(control);
      const moments = await this.due('moments');
      for (const doc of moments.docs) await this.attempt(doc.ref, async () => {
        if (!/^groups\/[^/]+\/moments\/[^/]+$/.test(doc.ref.path)) throw new Error('Unexpected moment path.');
        const groupId = doc.ref.parent.parent!.id, mid = doc.id;
        const ready = await this.db.runTransaction(async tx => {
          const current = await tx.get(doc.ref), data = current.data();
          if (!data?.cleanupPending || data.cleanupAfter.toMillis() > this.now()) return false;
          if (data.status === 'ready' && data.expiresAt.toMillis() > this.now()) return false;
          if (!['ready', 'expired', 'retracted'].includes(data.status as string)) return false;
          tx.update(doc.ref, { status: data.status === 'retracted' ? 'retracted' : 'expired' }); return true;
        });
        if (!ready) return;
        const data = (await doc.ref.get()).data()!;
        const page = await this.purge(`groupMoments/${groupId}/${mid}/`, data.cleanupToken as string | undefined, result);
        await doc.ref.update({ cleanupPending: !!page.next, cleanupAfter: Timestamp.fromMillis(this.now() + CLEANUP_GRACE_MS),
          cleanupToken: page.next ?? FieldValue.delete(), ...(page.next ? {} : { cleanedAt: Timestamp.fromMillis(this.now()),
            caption: FieldValue.delete(), authorNameSnapshot: FieldValue.delete(), hobbyNameSnapshot: FieldValue.delete(),
            mediaPath: FieldValue.delete(), thumbnailPath: FieldValue.delete() }) });
        if (!page.next) result.moments++;
      }, result);

      const uploads = await this.due('momentUploads');
      for (const doc of uploads.docs) await this.attempt(doc.ref, async () => {
        if (!/^users\/[^/]+\/momentUploads\/[^/]+$/.test(doc.ref.path)) throw new Error('Unexpected upload path.');
        const uid = doc.ref.parent.parent!.id, mid = doc.id;
        const ticket = await this.db.runTransaction(async tx => {
          const current = await tx.get(doc.ref), data = current.data();
          if (!data?.cleanupPending || data.cleanupAfter.toMillis() > this.now()) return null;
          const moment = await tx.get(this.db.doc(`groups/${data.groupId}/moments/${mid}`));
          const expiry = moment.data()?.status === 'ready' ? moment.data()?.expiresAt?.toMillis() ?? 0 : 0;
          const wait = Math.max(data.uploadDeadline.toMillis() + CLEANUP_GRACE_MS,
            (data.leaseUntil?.toMillis() ?? 0) + CLEANUP_GRACE_MS, expiry);
          if (wait > this.now()) { tx.update(doc.ref, { cleanupAfter: Timestamp.fromMillis(wait) }); return null; }
          tx.update(doc.ref, { status: 'expired' }); return data;
        });
        if (!ticket) return;
        const source = await this.media.page(`momentStaging/${uid}/${mid}/`);
        for (const file of source.files) if (cleanupObjectPath(file.name)) { await this.media.remove(file); result.objects++; }
        const output = await this.purge(`groupMoments/${ticket.groupId}/${mid}/`, ticket.cleanupToken as string | undefined, result);
        const more = output.next ?? source.next;
        await doc.ref.update({ cleanupPending: !!more, cleanupAfter: Timestamp.fromMillis(this.now() + CLEANUP_GRACE_MS),
          cleanupToken: output.next ?? FieldValue.delete(), ...(more ? {} : { cleanedAt: Timestamp.fromMillis(this.now()),
            caption: FieldValue.delete(), authorNameSnapshot: FieldValue.delete(), hobbyNameSnapshot: FieldValue.delete(),
            leaseId: FieldValue.delete(), leaseUntil: FieldValue.delete() }) });
        if (!more) result.uploads++;
      }, result);

      const inbox = await this.db.collectionGroup('momentInbox').where('expiresAt', '<=', Timestamp.fromMillis(this.now()))
        .orderBy('expiresAt').limit(50).get();
      for (const doc of inbox.docs) if (/^users\/[^/]+\/momentInbox\/[^/]+$/.test(doc.ref.path)) {
        await this.attempt(doc.ref, async () => { await doc.ref.delete(); result.inbox++; }, result, false);
      }
      const jobs = await this.db.collection('momentOutbox').where('cleanupPending', '==', true)
        .where('cleanupAfter', '<=', Timestamp.fromMillis(this.now())).orderBy('cleanupAfter').limit(PAGE).get();
      for (const doc of jobs.docs) await this.attempt(doc.ref, async () => {
        const job = await doc.ref.get(), data = job.data();
        if (!data || data.expiresAt.toMillis() + OUTBOX_RETENTION_MS > this.now()) return;
        if (!data.done && data.nextAttemptAt.toMillis() > this.now()) return; // Active delivery lease.
        await doc.ref.update({ done: true });
        // Recover receipts whose parent was never written by an older/crashed
        // sender. Document-name bounds keep the scan inside this outbox only.
        const orphanReceipts = await this.receipts(doc.ref).limit(50).get();
        const receiptBatch = this.db.batch();
        for (const receipt of orphanReceipts.docs) if (/^momentOutbox\/[^/]+\/deliveries\/[^/]+\/devices\/[^/]+$/.test(receipt.ref.path)) receiptBatch.delete(receipt.ref);
        await receiptBatch.commit();
        const deliveries = await doc.ref.collection('deliveries').limit(10).get();
        for (const delivery of deliveries.docs) {
          const devices = await delivery.ref.collection('devices').limit(10).get();
          const batch = this.db.batch(); devices.docs.forEach(device => batch.delete(device.ref)); await batch.commit();
          if (devices.size < 10) await delivery.ref.delete();
        }
        if ((await doc.ref.collection('deliveries').limit(1).get()).empty && (await this.receipts(doc.ref).limit(1).get()).empty) {
          await doc.ref.delete(); result.outboxes++;
        }
      }, result);

      const saved = (await control.get()).data() ?? {};
      for (const [prefix, key] of [['momentStaging/', 'stagingCursor'], ['groupMoments/', 'mediaCursor']] as const) {
        try {
          const page = await this.media.page(prefix, saved[key] as string | undefined);
          for (const file of page.files) if (cleanupObjectPath(file.name) && Number.isFinite(file.createdAt) && file.createdAt <= this.now() - ORPHAN_AGE_MS) {
            if (await this.orphan(file)) { await this.media.remove(file); result.objects++; }
          }
          await control.update({ [key]: page.next ?? FieldValue.delete() });
        } catch (_) { result.errors++; } // Keep the old cursor for a retry.
      }
    } finally {
      await this.db.runTransaction(async tx => {
        const current = await tx.get(control);
        if (current.data()?.lease === lease) tx.update(control, { leaseUntil: Timestamp.fromMillis(0), lastRunAt: Timestamp.fromMillis(this.now()), lastResult: result });
      });
    }
    return result;
  }
  private due(collection: string) {
    return this.db.collectionGroup(collection).where('cleanupPending', '==', true)
      .where('cleanupAfter', '<=', Timestamp.fromMillis(this.now())).orderBy('cleanupAfter').limit(PAGE).get();
  }
  private receipts(ref: DocumentReference) {
    return this.db.collectionGroup('devices').orderBy(FieldPath.documentId())
      .startAt(this.db.doc(`${ref.path}/a/a`)).endBefore(this.db.doc(`${ref.path}/z/z`));
  }
  private async backfill(control: DocumentReference) {
    // Bounded migration of pre-step-4 emulator/imported metadata; never clear an
    // existing false flag or walk unrelated collections with the same name.
    for (const name of ['moments', 'momentUploads', 'momentOutbox']) {
      const saved = (await control.get()).data() ?? {}, key = `backfill_${name}`;
      let query = name === 'momentOutbox' ? this.db.collection(name).orderBy(FieldPath.documentId()).limit(PAGE)
        : this.db.collectionGroup(name).orderBy(FieldPath.documentId()).limit(PAGE);
      if (saved[key]) query = query.startAfter(name === 'momentOutbox' ? saved[key] : this.db.doc(saved[key] as string));
      const docs = await query.get();
      for (const doc of docs.docs) {
        if (!(name === 'momentOutbox' ? /^momentOutbox\/[^/]+$/ : name === 'moments'
          ? /^groups\/[^/]+\/moments\/[^/]+$/ : /^users\/[^/]+\/momentUploads\/[^/]+$/).test(doc.ref.path)) continue;
        await this.db.runTransaction(async tx => {
          const current = await tx.get(doc.ref), data = current.data();
          if (!data || data.cleanupPending !== undefined) return;
          const after = name === 'momentUploads'
            ? data.status === 'published' ? data.expiresAt : data.uploadDeadline instanceof Timestamp ? Timestamp.fromMillis(data.uploadDeadline.toMillis() + CLEANUP_GRACE_MS) : null
            : name === 'momentOutbox' ? data.expiresAt instanceof Timestamp ? Timestamp.fromMillis(data.expiresAt.toMillis() + OUTBOX_RETENTION_MS) : null
            : data.status === 'retracted' ? data.retractedAt ?? data.expiresAt : data.expiresAt;
          if (after instanceof Timestamp) tx.update(doc.ref, { cleanupPending: true, cleanupAfter: after });
        });
      }
      await control.update({ [key]: docs.size === PAGE ? (name === 'momentOutbox' ? docs.docs.at(-1)!.id : docs.docs.at(-1)!.ref.path) : FieldValue.delete() });
    }
  }
  private async purge(prefix: string, token: string | undefined, result: Summary) {
    const page = await this.media.page(prefix, token);
    for (const file of page.files) if (cleanupObjectPath(file.name)) { await this.media.remove(file); result.objects++; }
    return page;
  }
  private async attempt(ref: DocumentReference, work: () => Promise<void>, result: Summary, reschedule = true) {
    try { await work(); } catch (_) {
      result.errors++;
      if (reschedule) await ref.update({ cleanupAfter: Timestamp.fromMillis(this.now() + CLEANUP_GRACE_MS) }).catch(() => undefined);
    }
  }
  private async orphan(file: CleanupObject): Promise<boolean> {
    const parts = file.name.split('/');
    if (parts[0] === 'groupMoments') {
      const moment = await this.db.doc(`groups/${parts[1]}/moments/${parts[2]}`).get();
      return !moment.exists || (moment.data()?.status !== 'ready' || (moment.data()?.expiresAt?.toMillis() ?? Infinity) <= this.now());
    }
    const session = await this.db.doc(`users/${parts[1]}/momentUploads/${parts[2]}`).get();
    if (!session.exists) return true;
    const data = session.data()!;
    return data.status === 'expired' || (data.uploadDeadline.toMillis() + CLEANUP_GRACE_MS <= this.now() &&
      (data.leaseUntil?.toMillis() ?? 0) + CLEANUP_GRACE_MS <= this.now() && data.status !== 'published');
  }
}
