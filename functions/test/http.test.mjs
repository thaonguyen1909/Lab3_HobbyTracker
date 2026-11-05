import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { momentsHttp } from '../lib/moments_http.js';
import { MomentError } from '../lib/domain.js';

async function api(work, service = {}) {
  const server = createServer(momentsHttp(service, async token => {
    if (token !== 'test-token') throw new Error('Invalid token');
    return { uid: 'verified-owner' };
  }));
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const root = `http://127.0.0.1:${server.address().port}`;
  const post = (path, value, auth = true) => fetch(root + '/v1/' + path, {
    method: 'POST', headers: { 'Content-Type': 'application/json', ...(auth ? { Authorization: 'Bearer test-token' } : {}) }, body: JSON.stringify(value),
  });
  try { await work({ root, post }); } finally { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
}
test('health, no-store and missing token do not call service', async () => {
  await api(async ({ root, post }) => {
    assert.equal((await fetch(root + '/health')).status, 200);
    const result = await post('beginGroupMomentUpload', {}, false);
    assert.equal(result.status, 401); assert.match(result.headers.get('cache-control'), /no-store/);
  }, { begin() { assert.fail('Unauthenticated service call'); } });
});
test('verified UID is independent of caller authorId; service retains input validation', async () => {
  await api(async ({ post }) => {
    const result = await post('beginGroupMomentUpload', { authorId: 'attacker' });
    assert.equal(result.status, 200); assert.equal((await result.json()).data.owner, 'verified-owner');
  }, { begin(uid) { return { owner: uid }; } });
});
test('binary staging has verified owner and exact bytes', async () => {
  await api(async ({ root }) => {
    const result = await fetch(root + '/v1/stage?momentId=m1', { method: 'POST',
      headers: { Authorization: 'Bearer test-token', 'Content-Type': 'application/octet-stream' }, body: Buffer.from([1,2,3]) });
    assert.equal(result.status, 200);
  }, { stage(uid, input, bytes) { assert.equal(uid, 'verified-owner'); assert.equal(input.momentId, 'm1'); assert.deepEqual(bytes, Buffer.from([1,2,3])); return { uploaded: true }; } });
});
test('oversized binary and malformed JSON are rejected before service', async () => {
  await api(async ({ root }) => {
    for (const [path, type, body] of [['stage?momentId=m', 'application/octet-stream', Buffer.alloc(5 * 1024 * 1024 + 1)],
      ['beginGroupMomentUpload', 'application/json', '{bad']]) {
      const result = await fetch(root + '/v1/' + path, { method: 'POST', headers: { Authorization: 'Bearer test-token', 'Content-Type': type }, body });
      assert.equal(result.status, 400);
    }
  });
});
test('permission and expiry responses retain stable codes without internal errors', async () => {
  await api(async ({ post }) => {
    const result = await post('getGroupMoment', {});
    assert.equal(result.status, 403); assert.equal((await result.json()).error.code, 'permission-denied');
  }, { get() { throw new MomentError('permission-denied', 'Group membership is required.'); } });
});
test('unknown/prototype routes cannot invoke arbitrary service methods', async () => {
  await api(async ({ post }) => { for (const path of ['constructor', '__proto__', 'stage/../begin']) assert.equal((await post(path, {})).status, 404); });
});
