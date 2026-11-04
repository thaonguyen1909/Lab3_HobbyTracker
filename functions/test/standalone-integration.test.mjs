import { before, beforeEach, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { MomentService } from '../lib/moments.js';
import sharp from 'sharp';

if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Requires isolated Firestore emulator.');
const projectId = 'demo-hobbytracker-cloudinary-tests';
let app, db, service, bytes, clock, media;
const request = { requestId: 'request1', groupId: 'g1', hobbyId: 'h1', caption: 'Badminton' };
before(async () => {
  app = initializeApp({ projectId }); db = getFirestore(app);
  bytes = await sharp({ create: { width: 30, height: 30, channels: 3, background: '#087f72' } }).jpeg().toBuffer();
});
beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: 'DELETE' });
  clock = Date.now();
  const objects = new Map();
  media = { bucketName: 'cloudinary', async save(path, value) { if (objects.has(path)) throw new Error('Cannot overwrite'); objects.set(path, value); },
    async source(path) { if (!objects.has(path)) throw Object.assign(new Error('Missing'), { code: 404 }); return objects.get(path); }, async remove(path) { objects.delete(path); } };
  service = new MomentService(db, media, () => clock);
  for (const uid of ['alice', 'bob']) {
    await db.doc(`users/${uid}`).set({ displayName: uid });
    await db.doc(`users/${uid}/hobbies/h1`).set({ name: 'Badminton', archived: false });
    await db.doc(`groups/g1/members/${uid}`).set({ uid });
  }
  await db.doc('groups/g1').set({ name: 'Badminton' });
});
after(async () => { await db.terminate(); await deleteApp(app); });
test('API staging, publish, member viewer, expiry and immutable retry preserve lifecycle', async () => {
  const ticket = await service.begin('alice', request);
  assert.equal(ticket.bucket, 'cloudinary');
  await service.stage('alice', { momentId: ticket.momentId }, bytes);
  await service.stage('alice', { momentId: ticket.momentId }, bytes);
  const moment = await service.publish('alice', { momentId: ticket.momentId });
  assert.equal(Date.parse(moment.expiresAt) - Date.parse(moment.publishedAt), 10_800_000);
  assert.ok((await service.image('bob', { groupId: 'g1', momentId: ticket.momentId, variant: 'thumbnail' })).base64);
  assert.equal((await service.publish('alice', { momentId: ticket.momentId })).expiresAt, moment.expiresAt);
  clock = Date.parse(moment.expiresAt);
  await assert.rejects(service.image('bob', { groupId: 'g1', momentId: ticket.momentId, variant: 'thumbnail' }), { code: 'not-found' });
});
test('cross-owner, missing membership, malformed image and expired stage are rejected', async () => {
  const ticket = await service.begin('alice', request);
  await assert.rejects(service.stage('bob', { momentId: ticket.momentId }, bytes), { code: 'not-found' });
  await assert.rejects(service.stage('alice', { momentId: ticket.momentId }, Buffer.from('bad')), { code: 'invalid-argument' });
  await db.doc('groups/g1/members/alice').delete();
  await assert.rejects(service.stage('alice', { momentId: ticket.momentId }, bytes), { code: 'permission-denied' });
  await db.doc('groups/g1/members/alice').set({ uid: 'alice' });
  clock += 10 * 60_000;
  await assert.rejects(service.stage('alice', { momentId: ticket.momentId }, bytes), { code: 'deadline-exceeded' });
});
test('in-progress staging blocks concurrent upload and publish', async () => {
  const ticket = await service.begin('alice', request);
  await db.doc(`users/alice/momentUploads/${ticket.momentId}`).update({ stageLeaseUntil: Timestamp.fromMillis(clock + 150_000) });
  await assert.rejects(service.stage('alice', { momentId: ticket.momentId }, bytes), { code: 'aborted' });
  await assert.rejects(service.publish('alice', { momentId: ticket.momentId }), { code: 'aborted' });
});
test('repeated invalid upload attempts are bounded by a server-side per-owner quota', async () => {
  const ticket = await service.begin('alice', request);
  await db.doc('momentLimits/alice').set({ stageWindow: Math.floor(clock / 3_600_000), stageCount: 30 }, { merge: true });
  await assert.rejects(service.stage('alice', { momentId: ticket.momentId }, bytes), { code: 'resource-exhausted' });
});
test('revocation hides image before physical cleanup; non-author cannot retract', async () => {
  const ticket = await service.begin('alice', request);
  await service.stage('alice', { momentId: ticket.momentId }, bytes);
  await service.publish('alice', { momentId: ticket.momentId });
  await assert.rejects(service.retract('bob', { groupId: 'g1', momentId: ticket.momentId }), { code: 'permission-denied' });
  media.remove = async () => { throw new Error('Provider temporarily unavailable'); };
  await service.retract('alice', { groupId: 'g1', momentId: ticket.momentId });
  await assert.rejects(service.image('bob', { groupId: 'g1', momentId: ticket.momentId, variant: 'photo' }), { code: 'not-found' });
});
