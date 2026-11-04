import { before, beforeEach, after, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { collection, doc, getDocs, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { MomentDelivery } from '../lib/moment_delivery.js';

if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Only run against a demo emulator.');
// Separate namespace avoids the running Functions trigger racing injected delivery tests.
const projectId = 'demo-hobbytracker-delivery';
let app, db, env, now, sent, delivery;
const expiry = () => Timestamp.fromMillis(now + 10_800_000);
const client = uid => env.authenticatedContext(uid).firestore();
async function prefs(uid, value = { enabled: true, previewOnLockScreen: false }) {
  await db.doc(`users/${uid}/settings/momentNotifications`).set(value);
}
async function seed(mid = 'm1') {
  await db.doc(`groups/g1/moments/${mid}`).set({ authorId: 'alice', status: 'ready', expiresAt: expiry(), publishedAt: Timestamp.fromMillis(now) });
  await db.doc(`momentOutbox/${mid}`).set({ groupId: 'g1', authorId: 'alice', expiresAt: expiry(),
    done: false, cursor: '', nextAttemptAt: Timestamp.fromMillis(now) });
}
before(async () => {
  env = await initializeTestEnvironment({ projectId, firestore: { rules: fs.readFileSync(new URL('../../firebase/firestore.rules', import.meta.url), 'utf8') } });
  app = initializeApp({ projectId }, 'delivery-test'); db = getFirestore(app);
});
beforeEach(async () => {
  await env.clearFirestore(); now = Date.now(); sent = [];
  delivery = new MomentDelivery(db, { send: async message => { sent.push(message); return 'test-only-message-id'; } }, () => now);
  for (const uid of ['alice', 'bob']) {
    await db.doc(`groups/g1/members/${uid}`).set({ uid }); await prefs(uid);
    await db.doc(`users/${uid}/devices/device`).set({ token: `test-only-${uid}` });
  }
  await seed();
});
after(async () => { await env?.cleanup(); if (app) await deleteApp(app); });

test('member receives one reference inbox and data-only push; author and outsider do not', async () => {
  await prefs('charlie'); await db.doc('users/charlie/devices/device').set({ token: 'test-only-charlie' });
  await delivery.process('m1');
  assert.equal(sent.length, 1); assert.equal(sent[0].token, 'test-only-bob');
  assert.equal(sent[0].notification, undefined); assert.equal(sent[0].data.ownerId, 'bob');
  assert.deepEqual(Object.keys(sent[0].data).sort(), ['eventId','expiresAt','groupId','kind','momentId','ownerId']);
  assert.equal(sent[0].android.ttl, 10_800_000);
  assert.equal((await db.doc('users/bob/momentInbox/moment_m1').get()).exists, true);
  assert.equal((await db.doc('users/alice/momentInbox/moment_m1').get()).exists, false);
  assert.equal((await db.doc('users/charlie/momentInbox/moment_m1').get()).exists, false);
});
test('outbox retry preserves event/read state and does not resend completed delivery', async () => {
  await delivery.process('m1'); await db.doc('users/bob/momentInbox/moment_m1').update({ read: true });
  await db.doc('momentOutbox/m1').update({ done: false, cursor: '', nextAttemptAt: Timestamp.fromMillis(now) });
  await delivery.process('m1'); assert.equal(sent.length, 1);
  assert.equal((await db.doc('users/bob/momentInbox/moment_m1').get()).data().read, true);
});
for (const [name, change] of [
  ['default opt-out', () => db.doc('users/bob/settings/momentNotifications').delete()],
  ['muted group', () => db.doc('users/bob/momentGroupSettings/g1').set({ muted: true })],
  ['global groups off', () => db.doc('users/bob/settings/preferences').set({ groups: false })],
  ['removed membership', () => db.doc('groups/g1/members/bob').delete()],
  ['retracted moment', () => db.doc('groups/g1/moments/m1').update({ status: 'retracted' })],
]) test(`${name} suppresses inbox/push`, async () => {
  await change(); await delivery.process('m1'); assert.equal(sent.length, 0);
  assert.equal((await db.doc('users/bob/momentInbox/moment_m1').get()).exists, false);
});
test('expired outbox is closed without reading media or sending', async () => {
  now += 10_800_000; await delivery.process('m1'); assert.equal(sent.length, 0);
  assert.equal((await db.doc('momentOutbox/m1').get()).data().done, true);
});
test('emulator sender is explicitly disabled but genuine reference inbox is created', async () => {
  await new MomentDelivery(db, null, () => now).process('m1'); assert.equal(sent.length, 0);
  assert.equal((await db.doc('momentOutbox/m1/deliveries/bob').get()).data().status, 'emulator-skipped');
  assert.equal((await db.doc('users/bob/momentInbox/moment_m1').get()).exists, true);
});
test('transient send error retries due recipient without resetting read or sending author', async () => {
  let fails = true;
  delivery = new MomentDelivery(db, { send: async message => { if (fails) throw new Error('Temporary test transport'); sent.push(message); return 'test'; } }, () => now);
  await assert.rejects(delivery.process('m1'));
  await db.doc('users/bob/momentInbox/moment_m1').update({ read: true });
  now += 31_000; fails = false; await delivery.retryDue(); assert.equal(sent.length, 1);
  assert.equal((await db.doc('users/bob/momentInbox/moment_m1').get()).data().read, true);
});
test('invalid registration token is pruned, generic transport error is not treated as success', async () => {
  delivery = new MomentDelivery(db, { send: async () => { throw Object.assign(new Error('Test invalid token'), { code: 'messaging/registration-token-not-registered' }); } }, () => now);
  await delivery.process('m1'); assert.equal((await db.doc('users/bob/devices/device').get()).exists, false);
});
test('fan-out pagination continues from a bounded page and rechecks every recipient', async () => {
  for (let i = 0; i < 23; i++) { const uid = `member${i.toString().padStart(2,'0')}`;
    await db.doc(`groups/g1/members/${uid}`).set({ uid }); await prefs(uid); }
  await delivery.process('m1'); assert.equal((await db.doc('momentOutbox/m1').get()).data().done, false);
  now += 31_000; await delivery.retryDue();
  assert.equal((await db.doc('momentOutbox/m1').get()).data().done, true);
  assert.equal((await db.collectionGroup('momentInbox').get()).size, 24);
});
test('owner-only settings/mute/inbox rules reject forged entries and other-account reads', async () => {
  await assertSucceeds(setDoc(doc(client('bob'), 'users/bob/settings/momentNotifications'), { enabled: true, previewOnLockScreen: false }));
  await assertFails(setDoc(doc(client('charlie'), 'users/bob/settings/momentNotifications'), { enabled: true, previewOnLockScreen: true }));
  await assertFails(setDoc(doc(client('bob'), 'users/bob/settings/momentNotifications'), { enabled: true, previewOnLockScreen: false, role: 'admin' }));
  await assertSucceeds(setDoc(doc(client('bob'), 'users/bob/momentGroupSettings/g1'), { muted: false }));
  await assertFails(setDoc(doc(client('charlie'), 'users/charlie/momentGroupSettings/g1'), { muted: true }));
  await delivery.process('m1');
  await assertSucceeds(getDocs(collection(client('bob'), 'users/bob/momentInbox')));
  await assertFails(getDoc(doc(client('charlie'), 'users/bob/momentInbox/moment_m1')));
  await assertFails(setDoc(doc(client('bob'), 'users/bob/momentInbox/fake'), { eventId: 'forged' }));
  await assertSucceeds(updateDoc(doc(client('bob'), 'users/bob/momentInbox/moment_m1'), { read: true }));
  await assertFails(updateDoc(doc(client('bob'), 'users/bob/momentInbox/moment_m1'), { momentId: 'another' }));
  await assertFails(getDoc(doc(client('bob'), 'momentOutbox/m1')));
});
