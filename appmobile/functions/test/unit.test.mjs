import { test } from 'node:test';
import assert from 'node:assert/strict';
import sharp from 'sharp';
import { beginInput, listInput, id, requireUid, stableMomentId, MAX_UPLOAD_BYTES,
  MAX_PHOTO_BYTES, MAX_THUMBNAIL_BYTES, LIFETIME_MS } from '../lib/domain.js';
import { normalizePhoto } from '../lib/media.js';

test('requires verified auth context and rejects path injection', () => {
  assert.throws(() => requireUid(undefined), { code: 'unauthenticated' });
  for (const value of ['../private', 'a/b', '', '.', 'x'.repeat(129), 123]) {
    assert.throws(() => id(value), { code: 'invalid-argument' });
  }
  assert.equal(id('group_abc-01'), 'group_abc-01');
});

test('request shape prevents spoofed authors, lifetimes and arbitrary file paths', () => {
  const valid = { requestId: 'request1', groupId: 'group1', hobbyId: 'hobby1', caption: '  Great game  ' };
  assert.equal(beginInput(valid).caption, 'Great game');
  for (const field of ['authorId', 'expiresAt', 'lifetime', 'stagingPath']) {
    assert.throws(() => beginInput({ ...valid, [field]: 'forged' }), { code: 'invalid-argument' });
  }
  assert.throws(() => beginInput(null), { code: 'invalid-argument' });
});

test('caption counts Unicode characters, not UTF-16 code units', () => {
  const valid = { requestId: 'r1', groupId: 'g1', hobbyId: 'h1' };
  assert.equal([...beginInput({ ...valid, caption: '🏸'.repeat(160) }).caption].length, 160);
  assert.throws(() => beginInput({ ...valid, caption: 'a'.repeat(161) }), { code: 'invalid-argument' });
});

test('request IDs are stable within an owner and distinct across accounts', () => {
  assert.equal(stableMomentId('alice', 'r1'), stableMomentId('alice', 'r1'));
  assert.notEqual(stableMomentId('alice', 'r1'), stableMomentId('bob', 'r1'));
  assert.equal(LIFETIME_MS, 10_800_000);
});

test('pagination bounds and cursor are validated', () => {
  assert.equal(listInput({ groupId: 'g1' }).limit, 20);
  for (const limit of [0, -1, 21, 2.5, '10']) {
    assert.throws(() => listInput({ groupId: 'g1', limit }), { code: 'invalid-argument' });
  }
  assert.throws(() => listInput({ groupId: 'g1', cursor: { expiresAtMs: NaN, momentId: 'm1' } }), { code: 'invalid-argument' });
  assert.throws(() => listInput({ groupId: 'g1', cursor: { expiresAtMs: 123, momentId: '../m' } }), { code: 'invalid-argument' });
});

test('valid image is resized and EXIF/GPS removed from photo and thumbnail', async () => {
  const source = await sharp({ create: { width: 2000, height: 1800, channels: 3, background: '#087f72' } })
    .jpeg().withMetadata({ orientation: 6 }).toBuffer();
  assert.ok((await sharp(source).metadata()).exif);
  const result = await normalizePhoto(source);
  for (const bytes of [result.photo, result.thumbnail]) {
    const data = await sharp(bytes).metadata();
    assert.equal(data.format, 'jpeg');
    assert.equal(data.exif, undefined);
    assert.equal(data.orientation, undefined);
  }
  const photo = await sharp(result.photo).metadata(), thumb = await sharp(result.thumbnail).metadata();
  assert.ok(photo.width <= 1600 && photo.height <= 1600);
  assert.ok(thumb.width <= 512 && thumb.height <= 512);
  assert.ok(result.photo.length <= MAX_PHOTO_BYTES && result.thumbnail.length <= MAX_THUMBNAIL_BYTES);
});

test('fake images, oversized payloads and unsupported formats are rejected', async () => {
  for (const bytes of [Buffer.from('not an image'), Buffer.alloc(0), Buffer.alloc(MAX_UPLOAD_BYTES + 1),
    Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><rect width="20" height="20"/></svg>')]) {
    await assert.rejects(normalizePhoto(bytes), { code: 'invalid-argument' });
  }
});

test('decompressed image pixel limit prevents tiny compressed image bombs', async () => {
  const bytes = await sharp({ create: { width: 6000, height: 5000, channels: 3, background: '#000000' } }).png().toBuffer();
  assert.ok(bytes.length < MAX_UPLOAD_BYTES);
  await assert.rejects(normalizePhoto(bytes), { code: 'invalid-argument' });
});
