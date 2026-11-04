import { before, beforeEach, after, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore as adminFirestore, Timestamp } from 'firebase-admin/firestore';
import { getStorage as adminStorage } from 'firebase-admin/storage';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, getDocs, collection, setDoc, updateDoc } from 'firebase/firestore';
import { ref, uploadBytes, getBytes, deleteObject, getDownloadURL, listAll } from 'firebase/storage';
import sharp from 'sharp';
import { MomentService } from '../lib/moments.js';
import { MomentMediaStore } from '../lib/media.js';
import { LIFETIME_MS, MAX_UPLOAD_BYTES } from '../lib/domain.js';

// Never permit this suite to fall through to a live Firebase project.
if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_STORAGE_EMULATOR_HOST ||
    !process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('Run only via the moments emulator script.');
const projectId = 'demo-hobbytracker-moments';
const bucketName = `${projectId}.appspot.com`;
const firebaseRoot = new URL('../../firebase/', import.meta.url);
let env, adminApp, db, bucket, service, image;
let clock;
const client = uid => env.authenticatedContext(uid);
const request = (requestId = 'request1', extra = {}) => ({ requestId, groupId: 'g1', hobbyId: 'h1', caption: 'Playing badminton', ...extra });
const storageFile = (uid, path) => ref(client(uid).storage(`gs://${bucketName}`), path);

async function published(requestId = 'request1', extra = {}) {
  const upload = await service.begin('alice', request(requestId, extra));
  await uploadBytes(storageFile('alice', upload.stagingPath), image, { contentType: 'image/jpeg' });
  const moment = await service.publish('alice', { momentId: upload.momentId });
  return { upload, moment };
}

before(async () => {
  env = await initializeTestEnvironment({ projectId,
    firestore: { rules: fs.readFileSync(new URL('firestore.rules', firebaseRoot), 'utf8') },
    storage: { rules: fs.readFileSync(new URL('storage.rules', firebaseRoot), 'utf8') },
  });
  adminApp = initializeApp({ projectId, storageBucket: bucketName });
  db = adminFirestore(adminApp);
  bucket = adminStorage(adminApp).bucket();
  image = await sharp({ create: { width: 800, height: 600, channels: 3, background: '#087f72' } }).jpeg().toBuffer();
});

beforeEach(async () => {
  await env.clearFirestore();
  // Only the explicitly named local emulator bucket, never a cloud bucket.
  await bucket.deleteFiles({ force: true });
  clock = Date.now();
  service = new MomentService(db, new MomentMediaStore(bucketName), () => clock);
  const batch = db.batch();
  for (const uid of ['alice', 'bob', 'charlie']) {
    batch.set(db.doc(`users/${uid}`), { role: 'user', displayName: uid, createdAt: Timestamp.now() });
  }
  batch.set(db.doc('users/alice/hobbies/h1'), { name: 'Badminton', archived: false });
  batch.set(db.doc('groups/g1'), { ownerId: 'alice', name: 'Badminton group' });
  for (const uid of ['alice', 'bob']) batch.set(db.doc(`groups/g1/members/${uid}`), { uid, joinedAt: Timestamp.now() });
  await batch.commit();
});

after(async () => { await env?.cleanup(); if (adminApp) await deleteApp(adminApp); });

test('A uploads and publishes; member B reads photo/thumbnail; outsider C and anonymous are denied', async () => {
  const { moment } = await published();
  assert.equal((await service.get('bob', { groupId: 'g1', momentId: moment.momentId })).caption, 'Playing badminton');
  assert.equal((await service.list('bob', { groupId: 'g1' })).items.length, 1);
  await assertSucceeds(getDoc(doc(client('bob').firestore(), `groups/g1/moments/${moment.momentId}`)));
  const lookup = { groupId: 'g1', momentId: moment.momentId };
  for (const variant of ['photo', 'thumbnail']) {
    const result = await service.image('bob', { ...lookup, variant });
    assert.ok(Buffer.from(result.base64, 'base64').length > 0);
    assert.equal(result.contentType, 'image/jpeg');
  }
  await assertFails(getBytes(storageFile('bob', moment.mediaPath)));
  await assert.rejects(service.image('charlie', { ...lookup, variant: 'photo' }), { code: 'permission-denied' });
  await assert.rejects(service.get('charlie', { groupId: 'g1', momentId: moment.momentId }), { code: 'permission-denied' });
  await assert.rejects(service.list('charlie', { groupId: 'g1' }), { code: 'permission-denied' });
  await assertFails(getDoc(doc(client('charlie').firestore(), `groups/g1/moments/${moment.momentId}`)));
  await assertFails(getBytes(storageFile('charlie', moment.mediaPath)));
  await assertFails(getBytes(ref(env.unauthenticatedContext().storage(`gs://${bucketName}`), moment.mediaPath)));
});

test('begin and publish retries are stable, owner-bound and never extend the three-hour expiry', async () => {
  const first = await service.begin('alice', request());
  const retry = await service.begin('alice', request());
  assert.equal(first.momentId, retry.momentId);
  await assert.rejects(service.begin('alice', request('request1', { caption: 'Changed content' })), { code: 'already-exists' });
  await uploadBytes(storageFile('alice', first.stagingPath), image, { contentType: 'image/jpeg' });
  const moment = await service.publish('alice', { momentId: first.momentId });
  assert.equal(Date.parse(moment.expiresAt) - Date.parse(moment.publishedAt), LIFETIME_MS);
  clock += 60_000;
  assert.deepEqual(await service.publish('alice', { momentId: first.momentId }), moment);
  assert.equal((await db.collection('groups/g1/moments').get()).size, 1);
  await assert.rejects(service.publish('bob', { momentId: first.momentId }), { code: 'not-found' });
});

test('clients cannot forge published records, edit timestamps, access quotas or read another upload session', async () => {
  const { moment, upload } = await published();
  const firestore = client('alice').firestore();
  await assertFails(setDoc(doc(firestore, 'groups/g1/moments/forged'), { status: 'ready', authorId: 'bob' }));
  await assertFails(updateDoc(doc(firestore, `groups/g1/moments/${moment.momentId}`), { expiresAt: new Date('2030-01-01') }));
  await assertFails(getDocs(collection(client('bob').firestore(), 'groups/g1/moments')));
  await assertFails(getDoc(doc(firestore, 'momentLimits/alice')));
  await assertFails(getDoc(doc(client('bob').firestore(), `users/alice/momentUploads/${upload.momentId}`)));
  await assertFails(updateDoc(doc(firestore, `users/alice/momentUploads/${upload.momentId}`), { status: 'uploading' }));
  await assertSucceeds(getDoc(doc(firestore, `users/alice/momentUploads/${upload.momentId}`)));
});

test('expiry blocks backend reads, Firestore and Storage even while the media object still exists', async () => {
  const { moment } = await published();
  const past = Timestamp.fromMillis(clock - 1000);
  await db.doc(`groups/g1/moments/${moment.momentId}`).update({ expiresAt: past });
  assert.equal((await bucket.file(moment.mediaPath).exists())[0], true);
  await assert.rejects(service.get('bob', { groupId: 'g1', momentId: moment.momentId }), { code: 'not-found' });
  await assert.rejects(service.image('bob', { groupId: 'g1', momentId: moment.momentId, variant: 'photo' }), { code: 'not-found' });
  assert.equal((await service.list('bob', { groupId: 'g1' })).items.length, 0);
  await assertFails(getDoc(doc(client('bob').firestore(), `groups/g1/moments/${moment.momentId}`)));
  await assertFails(getBytes(storageFile('bob', moment.mediaPath)));
  // Exact boundary uses injected server clock, not a caller-provided lifetime.
  await db.doc(`groups/g1/moments/${moment.momentId}`).update({ expiresAt: Timestamp.fromMillis(clock + 1) });
  clock += 1;
  await assert.rejects(service.get('bob', { groupId: 'g1', momentId: moment.momentId }), { code: 'not-found' });
});

test('removed group membership denies metadata and all new image reads', async () => {
  const { moment } = await published();
  await db.doc('groups/g1/members/bob').delete();
  await assert.rejects(service.list('bob', { groupId: 'g1' }), { code: 'permission-denied' });
  await assertFails(getDoc(doc(client('bob').firestore(), `groups/g1/moments/${moment.momentId}`)));
  await assertFails(getBytes(storageFile('bob', moment.thumbnailPath)));
});

test('image request rechecks expiry after downloading bytes', async () => {
  const { moment } = await published();
  const base = new MomentMediaStore(bucketName);
  const slowRead = new MomentService(db, { bucketName, save: base.save.bind(base), remove: base.remove.bind(base),
    source: async path => { const bytes = await base.source(path); clock = Date.parse(moment.expiresAt); return bytes; },
  }, () => clock);
  await assert.rejects(slowRead.image('bob', { groupId: 'g1', momentId: moment.momentId, variant: 'photo' }), { code: 'not-found' });
});

test('image request rechecks membership after downloading bytes', async () => {
  const { moment } = await published();
  const base = new MomentMediaStore(bucketName);
  const slowRead = new MomentService(db, { bucketName, save: base.save.bind(base), remove: base.remove.bind(base),
    source: async path => { const bytes = await base.source(path); await db.doc('groups/g1/members/bob').delete(); return bytes; },
  }, () => clock);
  await assert.rejects(slowRead.image('bob', { groupId: 'g1', momentId: moment.momentId, variant: 'photo' }), { code: 'permission-denied' });
});

test('staging requires its owner, a live session, size/type checks and immutable upload bytes', async () => {
  const upload = await service.begin('alice', request());
  await assertFails(uploadBytes(storageFile('bob', upload.stagingPath), image, { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(storageFile('alice', upload.stagingPath), image, { contentType: 'text/plain' }));
  await assertFails(uploadBytes(storageFile('alice', upload.stagingPath), new Uint8Array(), { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(storageFile('alice', upload.stagingPath), new Uint8Array(MAX_UPLOAD_BYTES + 1), { contentType: 'image/jpeg' }));
  await assertSucceeds(uploadBytes(storageFile('alice', upload.stagingPath), image, { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(storageFile('alice', upload.stagingPath), image, { contentType: 'image/jpeg' }));
  await assertFails(getBytes(storageFile('alice', upload.stagingPath)));
  await assertFails(uploadBytes(storageFile('alice', 'momentStaging/alice/unknown/source'), image, { contentType: 'image/jpeg' }));
});

test('expired and processing upload sessions reject new source uploads', async () => {
  const upload = await service.begin('alice', request());
  const session = db.doc(`users/alice/momentUploads/${upload.momentId}`);
  await session.update({ uploadDeadline: Timestamp.fromMillis(clock - 1000) });
  await assertFails(uploadBytes(storageFile('alice', upload.stagingPath), image, { contentType: 'image/jpeg' }));
  await assert.rejects(service.publish('alice', { momentId: upload.momentId }), { code: 'deadline-exceeded' });
  await session.update({ uploadDeadline: Timestamp.fromMillis(Date.now() + 60_000), status: 'processing' });
  await assertFails(uploadBytes(storageFile('alice', upload.stagingPath), image, { contentType: 'image/jpeg' }));
});

test('invalid image bytes never produce a published moment; retry is bounded', async () => {
  const upload = await service.begin('alice', request());
  await uploadBytes(storageFile('alice', upload.stagingPath), Buffer.from('fake JPEG'), { contentType: 'image/jpeg' });
  await assert.rejects(service.publish('alice', { momentId: upload.momentId }), { code: 'invalid-argument' });
  assert.equal((await db.collection('groups/g1/moments').get()).size, 0);
  assert.equal((await db.doc(`users/alice/momentUploads/${upload.momentId}`).get()).data().status, 'uploading');
  await db.doc('momentLimits/alice').set({ publishWindow: Math.floor(clock / 3_600_000), publishCount: 30 }, { merge: true });
  await assert.rejects(service.publish('alice', { momentId: upload.momentId }), { code: 'resource-exhausted' });
});

test('source missing, archived hobby, non-member and anonymous fail without publishing', async () => {
  await assert.rejects(service.begin(undefined, request()), { code: 'unauthenticated' });
  await assert.rejects(service.begin('charlie', request()), { code: 'permission-denied' });
  const upload = await service.begin('alice', request());
  await assert.rejects(service.publish('alice', { momentId: upload.momentId }), { code: 'failed-precondition' });
  await db.doc('users/alice/hobbies/h1').update({ archived: true });
  await assert.rejects(service.begin('alice', request('another')), { code: 'failed-precondition' });
  await assert.rejects(service.publish('alice', { momentId: upload.momentId }), { code: 'failed-precondition' });
});

test('only author retracts; failed physical deletion does not restore read permission', async () => {
  const { moment } = await published();
  const input = { groupId: 'g1', momentId: moment.momentId };
  await assert.rejects(service.retract('bob', input), { code: 'permission-denied' });
  const base = new MomentMediaStore(bucketName);
  const failingDelete = new MomentService(db, { bucketName, remove: async () => { throw new Error('simulated outage'); },
    source: base.source.bind(base), save: base.save.bind(base) }, () => clock);
  assert.equal((await failingDelete.retract('alice', input)).cleanupPending, true);
  assert.equal((await bucket.file(moment.mediaPath).exists())[0], true);
  await assertFails(getBytes(storageFile('bob', moment.mediaPath)));
  await assert.rejects(service.get('bob', input), { code: 'not-found' });
  assert.equal((await service.retract('alice', input)).cleanupPending, false);
  assert.equal((await bucket.file(moment.mediaPath).exists())[0], false);
  await assert.rejects(service.publish('alice', { momentId: moment.momentId }), { code: 'not-found' });
});

test('media has no public download token; list, replacement, stale generations and deletes are denied', async () => {
  const { moment } = await published();
  const file = storageFile('bob', moment.mediaPath);
  const [metadata] = await bucket.file(moment.mediaPath).getMetadata();
  assert.equal(metadata.metadata?.firebaseStorageDownloadTokens ?? '', '');
  await assert.rejects(getDownloadURL(file));
  await assertFails(listAll(ref(client('bob').storage(`gs://${bucketName}`), `groupMoments/g1/${moment.momentId}`)));
  await assertFails(uploadBytes(file, image, { contentType: 'image/jpeg' }));
  await assertFails(deleteObject(file));
  const stalePath = `groupMoments/g1/${moment.momentId}/stale/photo.jpg`;
  await bucket.file(stalePath).save(image);
  await assertFails(getBytes(storageFile('bob', stalePath)));
});

test('pagination is stable for tied expiration times and does not duplicate rows', async () => {
  for (const requestId of ['request1', 'request2', 'request3']) await published(requestId);
  const first = await service.list('bob', { groupId: 'g1', limit: 2 });
  assert.equal(first.items.length, 2);
  assert.ok(first.nextCursor);
  const second = await service.list('bob', { groupId: 'g1', limit: 2, cursor: first.nextCursor });
  assert.equal(second.items.length, 1);
  assert.equal(new Set([...first.items, ...second.items].map(item => item.momentId)).size, 3);
  assert.equal(second.nextCursor, null);
});

test('source download token is never copied into the published JPEG and source is removed', async () => {
  const upload = await service.begin('alice', request());
  await uploadBytes(storageFile('alice', upload.stagingPath), image,
    { contentType: 'image/jpeg', customMetadata: { firebaseStorageDownloadTokens: 'source-only-token' } });
  const moment = await service.publish('alice', { momentId: upload.momentId });
  assert.equal((await bucket.file(upload.stagingPath).exists())[0], false);
  const [metadata] = await bucket.file(moment.mediaPath).getMetadata();
  assert.equal(metadata.metadata?.firebaseStorageDownloadTokens ?? '', '');
  await assertFails(getDownloadURL(storageFile('bob', moment.mediaPath)));
});

test('processing lease blocks concurrent publication; rate limit bounds new uploads', async () => {
  const upload = await service.begin('alice', request());
  await db.doc(`users/alice/momentUploads/${upload.momentId}`).update({ status: 'processing', leaseId: 'another',
    leaseUntil: Timestamp.fromMillis(clock + 60_000) });
  await assert.rejects(service.publish('alice', { momentId: upload.momentId }), { code: 'aborted' });
  await db.doc('momentLimits/alice').set({ beginWindow: Math.floor(clock / 3_600_000), beginCount: 10 }, { merge: true });
  await assert.rejects(service.begin('alice', request('extra')), { code: 'resource-exhausted' });
  assert.equal((await service.begin('alice', request())).momentId, upload.momentId);
});

test('real callable HTTP validates auth and uploads through emulated Auth/Functions/Storage/Firestore', async () => {
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const signup = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator-only`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ returnSecureToken: true }),
  });
  assert.equal(signup.status, 200);
  const { localId: uid, idToken } = await signup.json();
  await db.doc(`groups/g1/members/${uid}`).set({ uid, joinedAt: Timestamp.now() });
  await db.doc(`users/${uid}`).set({ displayName: 'Callable author' });
  await db.doc(`users/${uid}/hobbies/h1`).set({ name: 'Badminton', archived: false });
  const baseUrl = `http://127.0.0.1:5001/${projectId}/asia-southeast1`;
  async function call(name, data, authenticated = true) {
    const response = await fetch(`${baseUrl}/${name}`, { method: 'POST',
      headers: { 'Content-Type': 'application/json', ...(authenticated ? { Authorization: `Bearer ${idToken}` } : {}) },
      body: JSON.stringify({ data }),
    });
    return { status: response.status, body: await response.json() };
  }
  assert.equal((await call('beginGroupMomentUpload', request(), false)).status, 401);
  assert.equal((await call('beginGroupMomentUpload', { ...request(), authorId: 'alice' })).status, 400);
  const begun = await call('beginGroupMomentUpload', request());
  assert.equal(begun.status, 200, JSON.stringify(begun.body));
  const upload = begun.body.result;
  await uploadBytes(ref(client(uid).storage(`gs://${upload.bucket}`), upload.stagingPath), image, { contentType: 'image/jpeg' });
  const published = await call('publishGroupMoment', { momentId: upload.momentId });
  assert.equal(published.status, 200, JSON.stringify(published.body));
  assert.equal((await call('listGroupMoments', { groupId: 'g1' })).body.result.items.length, 1);
  assert.equal((await call('getGroupMoment', { groupId: 'g1', momentId: upload.momentId })).status, 200);
  const imageResponse = await call('getGroupMomentImage', { groupId: 'g1', momentId: upload.momentId, variant: 'thumbnail' });
  assert.equal(imageResponse.status, 200);
  assert.ok(Buffer.from(imageResponse.body.result.base64, 'base64').length > 0);
  assert.equal((await call('retractGroupMoment', { groupId: 'g1', momentId: upload.momentId })).status, 200);
  assert.equal((await call('getGroupMoment', { groupId: 'g1', momentId: upload.momentId })).status, 404);
});
