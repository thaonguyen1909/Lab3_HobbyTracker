import { before, beforeEach, after, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { initializeTestEnvironment, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc } from 'firebase/firestore';
import sharp from 'sharp';
import { MomentService } from '../lib/moments.js';
import { MomentMediaStore } from '../lib/media.js';
import { MomentCleanup, CLEANUP_GRACE_MS, ORPHAN_AGE_MS } from '../lib/moment_cleanup.js';
import { MomentCleanupMedia } from '../lib/moment_cleanup_media.js';

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_STORAGE_EMULATOR_HOST) throw new Error('Demo emulators required.');
const projectId = 'demo-hobbytracker-cleanup', bucketName = `${projectId}.appspot.com`;
let env, app, db, bucket, now, service, cleanup, media, image;
const request = (requestId = 'request1') => ({ requestId, groupId: 'g1', hobbyId: 'h1', caption: 'Private activity caption' });
async function publish(requestId = 'request1') {
  const ticket = await service.begin('alice', request(requestId));
  await bucket.file(ticket.stagingPath).save(image);
  return { ticket, moment: await service.publish('alice', { momentId: ticket.momentId }) };
}
before(async () => {
  env = await initializeTestEnvironment({ projectId, firestore: { rules: fs.readFileSync(new URL('../../firebase/firestore.rules', import.meta.url), 'utf8') } });
  app = initializeApp({ projectId, storageBucket: bucketName }); db = getFirestore(app); bucket = getStorage(app).bucket();
  image = await sharp({create:{width:30,height:20,channels:3,background:'#087f72'}}).jpeg().toBuffer();
});
beforeEach(async () => {
  await env.clearFirestore(); await bucket.deleteFiles({ force: true }); now = Date.now();
  service = new MomentService(db, new MomentMediaStore(bucketName), () => now);
  media = new MomentCleanupMedia(bucketName); cleanup = new MomentCleanup(db, media, () => now);
  await db.doc('users/alice').set({ displayName: 'Alice' });
  await db.doc('users/alice/hobbies/h1').set({ name: 'Badminton', archived: false });
  await db.doc('groups/g1').set({ name: 'Badminton' });
  for (const uid of ['alice','bob']) await db.doc(`groups/g1/members/${uid}`).set({ uid });
});
after(async () => { await env?.cleanup(); if (app) await deleteApp(app); });

test('expired photo is denied before cleanup, deleted after cleanup, private snapshots redacted and retry cannot republish', async () => {
  const { ticket, moment } = await publish(); now += 10_800_000;
  await assert.rejects(service.image('bob', {groupId:'g1',momentId:moment.momentId,variant:'photo'}), e => e.code === 'not-found');
  assert.equal((await bucket.file(moment.mediaPath).exists())[0], true);
  const result = await cleanup.run(); assert.equal(result.errors, 0); assert.equal(result.moments, 1);
  assert.equal((await bucket.file(moment.mediaPath).exists())[0], false);
  const tombstone = (await db.doc(`groups/g1/moments/${moment.momentId}`).get()).data();
  assert.equal(tombstone.status, 'expired'); assert.equal(tombstone.caption, undefined); assert.equal(tombstone.cleanupPending, false);
  assert.equal((await db.doc(`users/alice/momentUploads/${ticket.momentId}`).get()).data().caption, undefined);
  await assert.rejects(service.begin('alice', request()), e => e.code === 'deadline-exceeded');
  await assert.rejects(service.publish('alice', {momentId:ticket.momentId}), e => e.code === 'deadline-exceeded');
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(), `groups/g1/moments/${moment.momentId}`)));
  assert.equal((await cleanup.run()).errors, 0);
});
test('abandoned upload cleans source and every failed output generation after a grace window', async () => {
  const ticket = await service.begin('alice', request());
  await bucket.file(ticket.stagingPath).save(image);
  const stale = `groupMoments/g1/${ticket.momentId}/stale/photo.jpg`; await bucket.file(stale).save(image);
  now += 600_000 + CLEANUP_GRACE_MS;
  const result = await cleanup.run(); assert.equal(result.uploads, 1);
  assert.equal((await bucket.file(ticket.stagingPath).exists())[0], false); assert.equal((await bucket.file(stale).exists())[0], false);
});
test('live moment, active upload and processing lease remain intact', async () => {
  const {moment} = await publish();
  const ticket = await service.begin('alice', request('processing')); await bucket.file(ticket.stagingPath).save(image);
  now += 600_000 + CLEANUP_GRACE_MS;
  await db.doc(`users/alice/momentUploads/${ticket.momentId}`).update({status:'processing',leaseUntil:Timestamp.fromMillis(now + 60_000)});
  assert.equal((await cleanup.run()).errors, 0);
  assert.equal((await bucket.file(moment.mediaPath).exists())[0], true); assert.equal((await bucket.file(ticket.stagingPath).exists())[0], true);
  assert.equal((await db.doc(`users/alice/momentUploads/${ticket.momentId}`).get()).data().status, 'processing');
});
test('storage deletion failure leaves deny state plus pending retry; recovery later deletes objects', async () => {
  const {moment} = await publish(); now += 10_800_000;
  const faulty = { page: media.page.bind(media), remove: async () => { throw new Error('Test transient storage outage'); } };
  assert.ok((await new MomentCleanup(db, faulty, () => now).run()).errors > 0);
  const ref = db.doc(`groups/g1/moments/${moment.momentId}`); assert.equal((await ref.get()).data().status, 'expired');
  assert.equal((await ref.get()).data().cleanupPending, true); assert.equal((await bucket.file(moment.mediaPath).exists())[0], true);
  await assert.rejects(service.get('bob',{groupId:'g1',momentId:moment.momentId}), e => e.code === 'not-found');
  now += CLEANUP_GRACE_MS; assert.equal((await cleanup.run()).errors, 0);
  assert.equal((await bucket.file(moment.mediaPath).exists())[0], false);
});
test('retracted photo is collected early, and repeating retract on a compact tombstone is harmless', async () => {
  const {moment} = await publish();
  const failing = new MomentService(db, { ...new MomentMediaStore(bucketName), remove: async () => {throw new Error('Test outage');} }, () => now);
  // Retract needs only remove; its failed best-effort deletion must leave cleanup work.
  assert.equal((await failing.retract('alice',{groupId:'g1',momentId:moment.momentId})).cleanupPending, true);
  await cleanup.run(); assert.equal((await bucket.file(moment.mediaPath).exists())[0], false);
  assert.equal((await service.retract('alice',{groupId:'g1',momentId:moment.momentId})).cleanupPending, false);
});
test('orphan sweeper deletes only old generated moment leaves and preserves PDF, history and live replacements', async () => {
  await bucket.file('users/alice/reports/report.pdf').save(Buffer.from('KEEP PDF'));
  await db.doc('users/alice/history/r1').set({ notes: 'KEEP HISTORY' });
  const orphan = 'groupMoments/g1/orphan/old/photo.jpg', source = 'momentStaging/alice/missing/source';
  await bucket.file(orphan).save(image); await bucket.file(source).save(image);
  now += ORPHAN_AGE_MS + 1000;
  const live = 'groupMoments/g1/live/new/photo.jpg'; await bucket.file(live).save(image);
  await db.doc('groups/g1/moments/live').set({status:'ready', expiresAt:Timestamp.fromMillis(now+10_800_000)});
  await cleanup.run();
  assert.equal((await bucket.file(orphan).exists())[0], false); assert.equal((await bucket.file(source).exists())[0], false);
  assert.equal((await bucket.file(live).exists())[0], true); assert.equal((await bucket.file('users/alice/reports/report.pdf').exists())[0], true);
  assert.deepEqual((await db.doc('users/alice/history/r1').get()).data(), {notes:'KEEP HISTORY'});
});
test('forged mediaPath cannot cause cross-namespace deletion', async () => {
  const target = 'users/alice/reports/private.pdf'; await bucket.file(target).save(image);
  await db.doc('groups/g1/moments/forged').set({status:'ready',expiresAt:Timestamp.fromMillis(now-1),mediaPath:target,thumbnailPath:target});
  await cleanup.run(); assert.equal((await bucket.file(target).exists())[0], true);
  await assert.rejects(media.page('users/alice/reports/')); await assert.rejects(media.remove({name:target,generation:'1',createdAt:0}));
});
test('expired inbox across accounts is deleted; live inbox and private unrelated settings remain', async () => {
  for (const uid of ['alice','bob']) {
    await db.doc(`users/${uid}/momentInbox/expired`).set({expiresAt:Timestamp.fromMillis(now-1)});
    await db.doc(`users/${uid}/momentInbox/live`).set({expiresAt:Timestamp.fromMillis(now+1000)});
  }
  const result = await cleanup.run(); assert.equal(result.inbox, 2);
  assert.equal((await db.doc('users/bob/momentInbox/live').get()).exists, true);
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(), 'momentMaintenance/cleanup')));
});
test('outbox retention removes nested delivery receipts in bounded batches and leaves a live outbox alone', async () => {
  await db.doc('users/bob/devices/registered').set({token:'TEST_ONLY_KEEP_DEVICE'});
  const old = {expiresAt:Timestamp.fromMillis(now-ORPHAN_AGE_MS-1),done:true,nextAttemptAt:Timestamp.fromMillis(0)};
  await db.doc('momentOutbox/old').set(old);
  for (let i=0;i<13;i++) await db.doc(`momentOutbox/old/deliveries/u${i}/devices/d1`).set({sentAt:Timestamp.now()});
  await db.doc('momentOutbox/live').set({...old, expiresAt:Timestamp.fromMillis(now+1000)});
  for (let i=0;i<3;i++) { await cleanup.run(); now += CLEANUP_GRACE_MS; }
  assert.equal((await db.doc('momentOutbox/old').get()).exists, false);
  assert.equal((await db.doc('momentOutbox/old/deliveries/u1/devices/d1').get()).exists, false);
  assert.equal((await db.doc('momentOutbox/live').get()).exists, true);
  assert.equal((await db.doc('users/bob/devices/registered').get()).data().token, 'TEST_ONLY_KEEP_DEVICE');
});
test('concurrent cleanup respects the maintenance lease', async () => {
  await db.doc('momentMaintenance/cleanup').set({leaseUntil:Timestamp.fromMillis(now+60_000)});
  const result = await cleanup.run(); assert.equal(result.busy, true); assert.equal(result.objects,0);
});
test('legacy metadata is backfilled, bounded pages advance and new cleanup flags are not reset', async () => {
  for(let i=0;i<23;i++) await db.doc(`groups/g1/moments/m${i.toString().padStart(2,'0')}`).set({status:'ready',expiresAt:Timestamp.fromMillis(now-1),caption:'private'});
  for(let i=0;i<4;i++) { await cleanup.run(); now += CLEANUP_GRACE_MS; }
  const docs = await db.collection('groups/g1/moments').get(); assert.equal(docs.size,23);
  assert.equal(docs.docs.filter(d=>d.data().cleanupPending === false && d.data().caption === undefined).length,23);
});
test('storage generation targeting never deletes a replacement created after listing', async () => {
  const path = 'momentStaging/alice/generation/source'; await bucket.file(path).save(image);
  const first = (await media.page('momentStaging/alice/generation/')).files[0];
  await bucket.file(path).save(Buffer.from('REPLACEMENT'));
  await media.remove(first).catch(error => { assert.ok([404,412].includes(Number(error.code))); });
  assert.equal((await bucket.file(path).download())[0].toString(), 'REPLACEMENT');
});
