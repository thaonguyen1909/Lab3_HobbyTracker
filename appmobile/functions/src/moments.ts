import { randomUUID } from 'node:crypto';
import { FieldPath, FieldValue, Timestamp, type DocumentData, type DocumentSnapshot,
  type Firestore, type Transaction } from 'firebase-admin/firestore';
import { beginInput, id, listInput, record, requireUid, stableMomentId, LIFETIME_MS,
  UPLOAD_WINDOW_MS, PROCESSING_LEASE_MS, MomentError } from './domain.js';
import { normalizePhoto, type MomentMediaStore } from './media.js';
import { CLEANUP_GRACE_MS, OUTBOX_RETENTION_MS } from './moment_cleanup.js';

type Media = Pick<MomentMediaStore, 'bucketName' | 'source' | 'save' | 'remove'>;
type Upload = {
  authorId: string; groupId: string; hobbyId: string; caption: string;
  authorNameSnapshot: string; hobbyNameSnapshot: string; stagingPath: string;
  status: string; uploadDeadline: Timestamp; leaseId?: string; leaseUntil?: Timestamp;
};

function member(snapshot: DocumentSnapshot): void {
  if (!snapshot.exists) throw new MomentError('permission-denied', 'Group membership is required.');
}

function activeHobby(snapshot: DocumentSnapshot): void {
  if (!snapshot.exists || snapshot.data()?.archived !== false) {
    throw new MomentError('failed-precondition', 'Select an existing hobby that has not been archived.');
  }
}

function available(data: DocumentData | undefined, now: number): asserts data is DocumentData {
  if (!data || data.status !== 'ready' || !(data.expiresAt instanceof Timestamp) || data.expiresAt.toMillis() <= now) {
    throw new MomentError('not-found', 'This moment has expired or is no longer available.');
  }
}

function view(momentId: string, groupId: string, data: DocumentData) {
  return { momentId, groupId, authorId: data.authorId as string,
    authorName: data.authorNameSnapshot as string, hobbyName: data.hobbyNameSnapshot as string,
    caption: data.caption as string, mediaPath: data.mediaPath as string,
    thumbnailPath: data.thumbnailPath as string,
    publishedAt: (data.publishedAt as Timestamp).toDate().toISOString(),
    expiresAt: (data.expiresAt as Timestamp).toDate().toISOString() };
}

/** Auth UID comes exclusively from the verified callable context. No SDK in Flutter views. */
export class MomentService {
  constructor(private readonly db: Firestore, private readonly media: Media,
    private readonly now: () => number = Date.now) {}

  private membership(groupId: string, uid: string) {
    return this.db.doc(`groups/${groupId}/members/${uid}`);
  }

  /** Standalone API upload: ownership comes from a verified ID token, never the body. */
  async stage(uidValue: string | undefined, input: unknown, bytes: Buffer) {
    const uid = requireUid(uidValue), momentId = id(record(input, ['momentId']).momentId);
    const ref = this.db.doc(`users/${uid}/momentUploads/${momentId}`), lease = randomUUID();
    const upload = await this.db.runTransaction(async tx => {
      const snapshot = await tx.get(ref), data = snapshot.data();
      if (!data) throw new MomentError('not-found', 'Upload session was not found.');
      const [membership, hobby, quota] = await tx.getAll(this.membership(data.groupId, uid),
        this.db.doc(`users/${uid}/hobbies/${data.hobbyId}`), this.db.doc(`momentLimits/${uid}`));
      member(membership); activeHobby(hobby);
      if (data.uploadDeadline.toMillis() <= this.now()) throw new MomentError('deadline-exceeded', 'Upload session expired.');
      if (data.status !== 'uploading' || (data.stageLeaseUntil?.toMillis() ?? 0) > this.now()) {
        throw new MomentError('aborted', 'This upload is already being processed. Retry shortly.');
      }
      if (data.sourceReady) return { path: data.stagingPath as string, ready: true };
      this.quota(tx, uid, quota, 'stage', this.now());
      tx.update(ref, { stageLease: lease, stageLeaseUntil: Timestamp.fromMillis(this.now() + PROCESSING_LEASE_MS) });
      return { path: data.stagingPath as string, ready: false };
    });
    if (upload.ready) return { uploaded: true };
    try {
      const normalized = await normalizePhoto(bytes);
      await this.media.save(upload.path, normalized.photo);
      await this.db.runTransaction(async tx => {
        const current = await tx.get(ref);
        if (current.data()?.stageLease !== lease) throw new MomentError('aborted', 'Upload ownership changed.');
        tx.update(ref, { sourceReady: true, stageLease: FieldValue.delete(), stageLeaseUntil: FieldValue.delete() });
      });
      return { uploaded: true };
    } catch (error) {
      await this.db.runTransaction(async tx => {
        const current = await tx.get(ref);
        if (current.data()?.stageLease === lease) tx.update(ref, { stageLease: FieldValue.delete(), stageLeaseUntil: FieldValue.delete() });
      });
      throw error;
    }
  }

  private quota(tx: Transaction, uid: string, snapshot: DocumentSnapshot,
    operation: 'begin' | 'publish' | 'stage' | 'read', now: number): void {
    const window = Math.floor(now / (operation === 'read' ? 60_000 : 3_600_000));
    const data = snapshot.data() ?? {};
    const count = data[`${operation}Window`] === window ? Number(data[`${operation}Count`] ?? 0) : 0;
    const limit = operation === 'begin' ? 10 : operation === 'read' ? 60 : 30;
    if (count >= limit) throw new MomentError('resource-exhausted', 'Too many requests. Please try again later.');
    tx.set(this.db.doc(`momentLimits/${uid}`), {
      [`${operation}Window`]: window, [`${operation}Count`]: count + 1,
    }, { merge: true });
  }

  async begin(uidValue: string | undefined, input: unknown) {
    const uid = requireUid(uidValue);
    const value = beginInput(input);
    const momentId = stableMomentId(uid, value.requestId);
    const sessionRef = this.db.doc(`users/${uid}/momentUploads/${momentId}`);
    const session = await this.db.runTransaction(async tx => {
      const [existing, membership, hobby, profile, group, quota] = await tx.getAll(
        sessionRef, this.membership(value.groupId, uid),
        this.db.doc(`users/${uid}/hobbies/${value.hobbyId}`), this.db.doc(`users/${uid}`),
        this.db.doc(`groups/${value.groupId}`), this.db.doc(`momentLimits/${uid}`));
      member(membership);
      activeHobby(hobby);
      if (!profile.exists || !group.exists) throw new MomentError('failed-precondition', 'Account or group is unavailable.');
      const now = this.now();
      if (existing.exists) {
        const previous = existing.data() as Upload;
        if (previous.status === 'expired') throw new MomentError('deadline-exceeded', 'Upload session expired. Start a new upload.');
        if (previous.groupId !== value.groupId || previous.hobbyId !== value.hobbyId || previous.caption !== value.caption) {
          throw new MomentError('already-exists', 'Use a new requestId for different content.');
        }
        if (previous.status !== 'published' && previous.uploadDeadline.toMillis() <= now) {
          throw new MomentError('deadline-exceeded', 'Upload session expired. Start a new upload.');
        }
        return previous;
      }
      this.quota(tx, uid, quota, 'begin', now);
      const created: Upload = {
        authorId: uid, groupId: value.groupId, hobbyId: value.hobbyId, caption: value.caption,
        authorNameSnapshot: [...String(profile.data()?.displayName ?? '')].slice(0, 80).join(''),
        hobbyNameSnapshot: [...String(hobby.data()?.name ?? '')].slice(0, 50).join(''),
        stagingPath: `momentStaging/${uid}/${momentId}/source`, status: 'uploading',
        uploadDeadline: Timestamp.fromMillis(now + UPLOAD_WINDOW_MS),
      };
      tx.create(sessionRef, { ...created, createdAt: Timestamp.fromMillis(now), cleanupPending: true,
        cleanupAfter: Timestamp.fromMillis(now + UPLOAD_WINDOW_MS + CLEANUP_GRACE_MS) });
      return created;
    });
    return { momentId, groupId: session.groupId, status: session.status,
      bucket: this.media.bucketName, stagingPath: session.stagingPath,
      uploadDeadline: session.uploadDeadline.toDate().toISOString() };
  }

  async publish(uidValue: string | undefined, input: unknown) {
    const uid = requireUid(uidValue);
    const momentId = id(record(input, ['momentId']).momentId);
    const sessionRef = this.db.doc(`users/${uid}/momentUploads/${momentId}`);
    const leaseId = randomUUID();
    const claim = await this.db.runTransaction(async tx => {
      const session = await tx.get(sessionRef);
      if (!session.exists) throw new MomentError('not-found', 'Upload session was not found.');
      const upload = session.data() as Upload;
      if (upload.status === 'expired') throw new MomentError('deadline-exceeded', 'Upload session expired.');
      const [membership, hobby, moment, quota] = await tx.getAll(
        this.membership(upload.groupId, uid), this.db.doc(`users/${uid}/hobbies/${upload.hobbyId}`),
        this.db.doc(`groups/${upload.groupId}/moments/${momentId}`), this.db.doc(`momentLimits/${uid}`));
      member(membership);
      const now = this.now();
      if (moment.exists) {
        const data = moment.data();
        available(data, now);
        return { upload, published: view(momentId, upload.groupId, data) };
      }
      activeHobby(hobby);
      if (upload.uploadDeadline.toMillis() <= now) throw new MomentError('deadline-exceeded', 'Upload session expired.');
      if ((session.data()?.stageLeaseUntil?.toMillis() ?? 0) > now) {
        throw new MomentError('aborted', 'The photo is still uploading. Retry shortly.');
      }
      if (upload.status === 'processing' && (upload.leaseUntil?.toMillis() ?? 0) > now) {
        throw new MomentError('aborted', 'This upload is already being processed. Retry shortly.');
      }
      if (!['uploading', 'processing'].includes(upload.status)) {
        throw new MomentError('failed-precondition', 'Upload cannot be published.');
      }
      this.quota(tx, uid, quota, 'publish', now);
      tx.update(sessionRef, { status: 'processing', leaseId,
        leaseUntil: Timestamp.fromMillis(now + PROCESSING_LEASE_MS) });
      return { upload, published: undefined };
    });
    if (claim.published) return claim.published;

    const { upload } = claim;
    // Per-attempt paths prevent a timed-out worker deleting/replacing a newer attempt's output.
    const prefix = `groupMoments/${upload.groupId}/${momentId}/${leaseId}`;
    const mediaPath = `${prefix}/photo.jpg`, thumbnailPath = `${prefix}/thumb.jpg`;
    const momentRef = this.db.doc(`groups/${upload.groupId}/moments/${momentId}`);
    try {
      let source: Buffer;
      try { source = await this.media.source(upload.stagingPath); }
      catch (error) {
        if ((error as { code?: number }).code === 404) {
          throw new MomentError('failed-precondition', 'Upload the image before publishing.');
        }
        throw error;
      }
      const normalized = await normalizePhoto(source);
      await this.media.save(mediaPath, normalized.photo);
      await this.media.save(thumbnailPath, normalized.thumbnail);
      const result = await this.db.runTransaction(async tx => {
        const [current, membership, hobby] = await tx.getAll(sessionRef,
          this.membership(upload.groupId, uid), this.db.doc(`users/${uid}/hobbies/${upload.hobbyId}`));
        member(membership);
        activeHobby(hobby);
        const now = this.now();
        if (current.data()?.status !== 'processing' || current.data()?.leaseId !== leaseId) {
          throw new MomentError('aborted', 'Processing ownership changed. Retry the request.');
        }
        if ((current.data()?.uploadDeadline as Timestamp).toMillis() <= now) {
          throw new MomentError('deadline-exceeded', 'Upload session expired.');
        }
        const data = { authorId: uid, authorNameSnapshot: upload.authorNameSnapshot,
          hobbyNameSnapshot: upload.hobbyNameSnapshot, caption: upload.caption,
          mediaPath, thumbnailPath, status: 'ready', publishedAt: Timestamp.fromMillis(now),
          expiresAt: Timestamp.fromMillis(now + LIFETIME_MS), cleanupPending: true,
          cleanupAfter: Timestamp.fromMillis(now + LIFETIME_MS) };
        tx.create(momentRef, data);
        tx.create(this.db.doc(`momentOutbox/${momentId}`), {
          groupId: upload.groupId, authorId: uid, expiresAt: data.expiresAt,
          publishedAt: data.publishedAt, done: false, cursor: '',
          nextAttemptAt: Timestamp.fromMillis(now), cleanupPending: true,
          cleanupAfter: Timestamp.fromMillis(now + LIFETIME_MS + OUTBOX_RETENTION_MS),
        });
        tx.update(sessionRef, { status: 'published', leaseId: FieldValue.delete(),
          leaseUntil: FieldValue.delete(), expiresAt: data.expiresAt, cleanupPending: true, cleanupAfter: data.expiresAt });
        return view(momentId, upload.groupId, data);
      });
      // Successful publication does not depend on best-effort staging cleanup.
      await this.media.remove(upload.stagingPath).catch(() => undefined);
      return result;
    } catch (error) {
      // A network error can hide a committed transaction. Never delete a committed image.
      const committed = await momentRef.get();
      if (committed.data()?.mediaPath === mediaPath) {
        const data = committed.data();
        available(data, this.now());
        return view(momentId, upload.groupId, data);
      }
      await Promise.allSettled([this.media.remove(mediaPath), this.media.remove(thumbnailPath)]);
      await this.db.runTransaction(async tx => {
        const current = await tx.get(sessionRef);
        if (current.data()?.status === 'processing' && current.data()?.leaseId === leaseId) {
          tx.update(sessionRef, { status: 'uploading', leaseId: FieldValue.delete(), leaseUntil: FieldValue.delete() });
        }
      });
      throw error;
    }
  }

  async list(uidValue: string | undefined, input: unknown) {
    const uid = requireUid(uidValue), value = listInput(input);
    const snapshots = await this.db.runTransaction(async tx => {
      const [membership, quota] = await tx.getAll(this.membership(value.groupId, uid), this.db.doc(`momentLimits/${uid}`));
      member(membership);
      let query = this.db.collection(`groups/${value.groupId}/moments`)
        .where('status', '==', 'ready').where('expiresAt', '>', Timestamp.fromMillis(this.now()))
        .orderBy('expiresAt').orderBy(FieldPath.documentId()).limit(value.limit + 1);
      if (value.cursor) query = query.startAfter(Timestamp.fromMillis(value.cursor.expiresAtMs), value.cursor.momentId);
      const found = await tx.get(query);
      this.quota(tx, uid, quota, 'read', this.now());
      return found.docs;
    });
    const serverNow = this.now();
    const live = snapshots.filter(doc => (doc.data().expiresAt as Timestamp).toMillis() > serverNow);
    const page = live.slice(0, value.limit);
    const last = page.at(-1);
    return { items: page.map(doc => view(doc.id, value.groupId, doc.data())),
      serverNow: new Date(serverNow).toISOString(),
      nextCursor: live.length > value.limit && last
        ? { expiresAtMs: (last.data().expiresAt as Timestamp).toMillis(), momentId: last.id } : null };
  }

  async get(uidValue: string | undefined, input: unknown) {
    const uid = requireUid(uidValue), value = record(input, ['groupId', 'momentId']);
    const groupId = id(value.groupId), momentId = id(value.momentId);
    return this.db.runTransaction(async tx => {
      const [membership, moment, quota] = await tx.getAll(this.membership(groupId, uid),
        this.db.doc(`groups/${groupId}/moments/${momentId}`), this.db.doc(`momentLimits/${uid}`));
      member(membership);
      const data = moment.data(), now = this.now();
      available(data, now);
      this.quota(tx, uid, quota, 'read', now);
      return { ...view(momentId, groupId, data), serverNow: new Date(now).toISOString() };
    });
  }

  async image(uidValue: string | undefined, input: unknown) {
    const uid = requireUid(uidValue), value = record(input, ['groupId', 'momentId', 'variant']);
    if (value.variant !== 'photo' && value.variant !== 'thumbnail') {
      throw new MomentError('invalid-argument', 'Choose photo or thumbnail.');
    }
    const lookup = { groupId: id(value.groupId), momentId: id(value.momentId) };
    const moment = await this.get(uid, lookup);
    const bytes = await this.media.source(value.variant === 'photo' ? moment.mediaPath : moment.thumbnailPath);
    // Check again after IO: expiration, retraction or membership can change while downloading.
    const current = await this.get(uid, lookup);
    return { contentType: 'image/jpeg', base64: bytes.toString('base64'),
      expiresAt: current.expiresAt, serverNow: current.serverNow };
  }

  async retract(uidValue: string | undefined, input: unknown) {
    const uid = requireUid(uidValue), value = record(input, ['groupId', 'momentId']);
    const groupId = id(value.groupId), momentId = id(value.momentId);
    const ref = this.db.doc(`groups/${groupId}/moments/${momentId}`);
    const paths = await this.db.runTransaction(async tx => {
      const moment = await tx.get(ref);
      if (!moment.exists || moment.data()?.authorId !== uid) {
        throw new MomentError('permission-denied', 'Only the author can retract this moment.');
      }
      if (moment.data()?.status !== 'retracted') {
        tx.update(ref, { status: 'retracted', retractedAt: Timestamp.fromMillis(this.now()),
          cleanupPending: true, cleanupAfter: Timestamp.fromMillis(this.now()) });
      }
      const prefix = `groupMoments/${groupId}/${momentId}/`;
      return [moment.data()?.mediaPath, moment.data()?.thumbnailPath].filter((path): path is string =>
        typeof path === 'string' && path.startsWith(prefix) && /\/[A-Za-z0-9_-]{1,128}\/(photo|thumb)\.jpg$/.test(path.slice(prefix.length - 1)));
    });
    // Rules deny access as soon as the transaction commits, even if deletion fails.
    const deleted = await Promise.allSettled(paths.map(path => this.media.remove(path)));
    return { momentId, status: 'retracted', cleanupPending: deleted.some(item => item.status === 'rejected') };
  }
}
