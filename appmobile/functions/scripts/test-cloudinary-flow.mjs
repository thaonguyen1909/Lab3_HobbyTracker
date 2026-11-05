// Real Cloudinary media + real HTTP adapter, isolated emulator Auth/Firestore only.
// No fake accounts, groups or posts are created in the production Firebase project.
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { createServer } from 'node:http';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import sharp from 'sharp';
import { CloudinaryMedia, configureCloudinary } from '../lib/cloudinary_media.js';
import { MomentService } from '../lib/moments.js';
import { momentsHttp } from '../lib/moments_http.js';

const projectId = 'demo-hobbytracker-cloudinary-flow';
for (const name of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!/^127\.0\.0\.1:\d+$/.test(process.env[name] ?? '')) throw new Error('Requires isolated loopback emulators.');
}
configureCloudinary();
const app = initializeApp({ projectId }), db = getFirestore(app), media = new CloudinaryMedia(db);
let now = Date.now();
const service = new MomentService(db, media, () => now);
const server = createServer(momentsHttp(service, token => getAuth(app).verifyIdToken(token, true)));
const checks = {}, diagnostics = {};
let failure = false;
try {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: 'DELETE' });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const root = `http://127.0.0.1:${server.address().port}`, run = randomUUID();
  const people = {};
  for (const alias of ['alice', 'bob', 'outsider']) {
    const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: `${alias}-${run}@example.test`, password: 'Emulator-only-test-123', returnSecureToken: true }),
    });
    const account = await response.json();
    assert.equal(response.status, 200);
    people[alias] = { uid: account.localId, token: account.idToken };
    await db.doc(`users/${account.localId}`).set({ displayName: alias });
  }
  await db.doc('groups/g1').set({ name: 'Isolated cloudinary flow' });
  for (const alias of ['alice', 'bob']) await db.doc(`groups/g1/members/${people[alias].uid}`).set({ uid: people[alias].uid });
  await db.doc(`users/${people.alice.uid}/hobbies/h1`).set({ name: 'Badminton', archived: false });
  async function call(method, value, alias = 'alice', image) {
    const result = await fetch(root + '/v1/' + method, { method: 'POST',
      headers: { Authorization: `Bearer ${people[alias].token}`, 'Content-Type': image ? 'application/octet-stream' : 'application/json' },
      body: image ?? JSON.stringify(value) });
    return { status: result.status, body: await result.json() };
  }
  const bytes = await sharp({ create: { width: 64, height: 48, channels: 3, background: '#087f72' } }).jpeg().toBuffer();
  const input = { requestId: run, groupId: 'g1', hobbyId: 'h1', caption: 'Isolated test' };
  const ticket = await call('beginGroupMomentUpload', input);
  assert.equal(ticket.status, 200); assert.equal(ticket.body.data.bucket, 'cloudinary');
  const mid = ticket.body.data.momentId, lookup = { groupId: 'g1', momentId: mid };
  assert.equal((await call(`stage?momentId=${mid}`, null, 'alice', bytes)).status, 200);
  assert.equal((await call(`stage?momentId=${mid}`, null, 'alice', bytes)).status, 200);
  checks.uploadAndIdempotentStage = true;
  const posted = await call('publishGroupMoment', { momentId: mid });
  assert.equal(posted.status, 200);
  const item = posted.body.data;
  assert.equal(Date.parse(item.expiresAt) - Date.parse(item.publishedAt), 10_800_000);
  const retry = await call('publishGroupMoment', { momentId: mid });
  assert.equal(retry.body.data.expiresAt, item.expiresAt);
  checks.publishAndIdempotentRetry = true;
  const listing = await call('listGroupMoments', { groupId: 'g1' }, 'bob');
  assert.equal(listing.status, 200); assert.equal(listing.body.data.items.length, 1);
  assert.equal((await call('getGroupMoment', lookup, 'bob')).status, 200);
  const photo = await call('getGroupMomentImage', { ...lookup, variant: 'photo' }, 'bob');
  assert.equal(photo.status, 200); assert.ok(Buffer.from(photo.body.data.base64, 'base64').length > 0);
  assert.equal(Object.hasOwn(photo.body.data, 'url'), false);
  checks.memberReadsPrivateMedia = true;
  assert.equal((await call('getGroupMomentImage', { ...lookup, variant: 'photo' }, 'outsider')).status, 403);
  assert.equal((await call('retractGroupMoment', lookup, 'bob')).status, 403);
  checks.outsiderAndNonAuthorDenied = true;
  await db.doc(`groups/g1/members/${people.bob.uid}`).delete();
  assert.equal((await call('getGroupMomentImage', { ...lookup, variant: 'photo' }, 'bob')).status, 403);
  await db.doc(`groups/g1/members/${people.bob.uid}`).set({ uid: people.bob.uid });
  checks.removedMemberDenied = true;
  now = Date.parse(item.expiresAt);
  assert.equal((await call('getGroupMomentImage', { ...lookup, variant: 'photo' }, 'bob')).status, 404);
  checks.threeHourBoundaryDenied = true;
  const retracted = await call('retractGroupMoment', lookup);
  assert.equal(retracted.status, 200); assert.equal(retracted.body.data.cleanupPending, false);
  assert.equal((await call('getGroupMoment', lookup, 'bob')).status, 404);
  checks.retractAndProviderDelete = true;
  const outbox = await db.doc(`momentOutbox/${mid}`).get();
  assert.equal(outbox.exists, true); assert.ok(outbox.data().expiresAt instanceof Timestamp);
  checks.durableOutboxCreated = true;
} catch (error) {
  failure = true; diagnostics.errorType = error instanceof Error ? error.name : 'Unknown';
  if (Number.isInteger(error.http_code)) diagnostics.providerStatus = error.http_code;
  // Assertion codes/HTTP statuses are safe; do not print response bodies or tokens.
  if (error.code === 'ERR_ASSERTION' && typeof error.actual === 'number') diagnostics.actualStatus = error.actual;
} finally {
  try {
    for (const prefix of ['momentStaging/', 'groupMoments/']) {
      const page = await media.page(prefix);
      assert.equal(page.next, undefined);
      for (const file of page.files) await media.remove(file);
    }
    checks.providerAssetsCleaned = true;
  } catch { failure = true; diagnostics.cleanupFailed = true; }
  server.closeAllConnections(); await new Promise(resolve => server.close(resolve));
  await db.terminate(); await deleteApp(app);
  console.log(JSON.stringify({ checkedAt: new Date().toISOString(), projectId, realCloudinary: true,
    productionFirebaseDataUsed: false, expiryUsesInjectedClock: true, checks, diagnostics }));
  if (failure) process.exitCode = 1;
}
