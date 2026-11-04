import { randomUUID } from 'node:crypto';
import { FieldPath, Timestamp, type Firestore } from 'firebase-admin/firestore';
import type { Message, Messaging } from 'firebase-admin/messaging';

export type MomentSender = Pick<Messaging, 'send'>;
const LEASE_MS = 150_000;
const PAGE_SIZE = 20;

/** Durable, bounded fan-out. No media/author/caption is sent through FCM. */
export class MomentDelivery {
  constructor(private readonly db: Firestore, private readonly sender: MomentSender | null,
    private readonly now: () => number = Date.now) {}

  async process(momentId: string): Promise<void> {
    const outbox = this.db.doc(`momentOutbox/${momentId}`);
    const lease = randomUUID();
    const job = await this.db.runTransaction(async tx => {
      const snap = await tx.get(outbox), data = snap.data();
      if (!data || data.done || data.nextAttemptAt.toMillis() > this.now()) return null;
      if (data.expiresAt.toMillis() <= this.now()) {
        tx.update(outbox, { done: true });
        return null;
      }
      tx.update(outbox, { lease, nextAttemptAt: Timestamp.fromMillis(this.now() + LEASE_MS) });
      return data;
    });
    if (!job) return;
    let cursor = job.cursor as string;
    let done = false;
    try {
      let query = this.db.collection(`groups/${job.groupId}/members`).orderBy(FieldPath.documentId()).limit(PAGE_SIZE);
      if (cursor) query = query.startAfter(cursor);
      const members = await query.get();
      for (const member of members.docs) {
        if (member.id !== job.authorId) await this.deliver(momentId, job.groupId as string, member.id);
        cursor = member.id;
      }
      done = members.size < PAGE_SIZE;
    } finally {
      await this.db.runTransaction(async tx => {
        const current = await tx.get(outbox);
        if (current.data()?.lease === lease) {
          tx.update(outbox, { cursor, done, nextAttemptAt: Timestamp.fromMillis(this.now() + (done ? 0 : 30_000)) });
        }
      });
    }
  }

  private async eligible(groupId: string, momentId: string, uid: string) {
    const [moment, membership, setting, mute, general] = await this.db.getAll(
      this.db.doc(`groups/${groupId}/moments/${momentId}`),
      this.db.doc(`groups/${groupId}/members/${uid}`),
      this.db.doc(`users/${uid}/settings/momentNotifications`),
      this.db.doc(`users/${uid}/momentGroupSettings/${groupId}`),
      this.db.doc(`users/${uid}/settings/preferences`));
    const data = moment.data();
    return data?.status === 'ready' && data.expiresAt.toMillis() > this.now() &&
      data.authorId !== uid && membership.exists && setting.data()?.enabled === true &&
      mute.data()?.muted !== true && general.data()?.groups !== false ? data : null;
  }

  private async deliver(momentId: string, groupId: string, uid: string): Promise<void> {
    const ref = this.db.doc(`momentOutbox/${momentId}/deliveries/${uid}`);
    const previous = await ref.get();
    if (['sent', 'skipped', 'emulator-skipped'].includes(previous.data()?.status as string)) return;
    const data = await this.eligible(groupId, momentId, uid);
    if (!data) { await ref.set({ status: 'skipped' }); return; }
    const eventId = `moment_${momentId}`;
    // Reference-only inbox is safe to retain after expiry. Media always needs a fresh authorized API read.
    const inbox = this.db.doc(`users/${uid}/momentInbox/${eventId}`);
    await this.db.runTransaction(async tx => {
      const old = await tx.get(inbox);
      if (!old.exists) tx.create(inbox, { eventId, groupId, momentId, expiresAt: data.expiresAt,
        publishedAt: data.publishedAt, read: false });
    });
    if (!this.sender) { await ref.set({ status: 'emulator-skipped' }); return; }
    // Keep a real parent before creating device receipts. A crash must not
    // leave a missing delivery parent invisible to collection queries.
    await ref.set({ status: 'sending' });
    const devices = await this.db.collection(`users/${uid}/devices`).limit(10).get();
    for (const device of devices.docs) {
      const token = device.data().token as unknown;
      if (typeof token !== 'string' || !token) continue;
      const sentRef = ref.collection('devices').doc(device.id);
      if ((await sentRef.get()).exists) continue;
      const live = await this.eligible(groupId, momentId, uid);
      if (!live) { await ref.set({ status: 'skipped' }); return; }
      const payload: Message = { token, data: { kind: 'moment', ownerId: uid, eventId,
        groupId, momentId, expiresAt: live.expiresAt.toDate().toISOString() },
        android: { priority: 'high', ttl: Math.max(0, live.expiresAt.toMillis() - this.now()) } };
      try {
        await this.sender.send(payload);
        await sentRef.set({ sentAt: Timestamp.fromMillis(this.now()) });
      } catch (error) {
        const code = (error as { code?: string }).code;
        if (code !== 'messaging/registration-token-not-registered' && code !== 'messaging/invalid-registration-token') throw error;
        await this.db.runTransaction(async tx => {
          const current = await tx.get(device.ref);
          if (current.data()?.token === token) tx.delete(device.ref);
        });
      }
    }
    await ref.set({ status: 'sent' });
  }

  async retryDue(): Promise<void> {
    const due = await this.db.collection('momentOutbox').where('done', '==', false)
      .where('nextAttemptAt', '<=', Timestamp.fromMillis(this.now())).orderBy('nextAttemptAt').limit(10).get();
    for (const job of due.docs) await this.process(job.id);
  }
}
