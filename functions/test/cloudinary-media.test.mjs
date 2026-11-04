import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Writable } from 'node:stream';
import { v2 as cloudinary } from 'cloudinary';
import { CloudinaryMedia } from '../lib/cloudinary_media.js';

function fixture() {
  const rows = new Map();
  const db = { doc(key) { return { key, async get() { return { data: () => rows.get(key) }; },
    async update(data) { rows.set(key, { ...rows.get(key), ...data }); } }; },
  async runTransaction(work) { return work({ get: ref => ref.get(), create(ref, data) { rows.set(ref.key, data); } }); } };
  return { media: new CloudinaryMedia(db), rows };
}
test('uploads use authenticated assets, no overwrite; same bytes recover; replacement denied', async () => {
  const original = cloudinary.uploader.upload_stream;
  let calls = 0;
  cloudinary.uploader.upload_stream = (options, callback) => {
    calls++; assert.equal(options.type, 'authenticated'); assert.equal(options.overwrite, false);
    return new Writable({ write(chunk, encoding, done) { done(); }, final(done) {
      callback(null, { type: 'authenticated', resource_type: 'image', public_id: options.public_id, asset_id: 'asset-one', bytes: 3 }); done();
    } });
  };
  try {
    const { media } = fixture(), path = 'groupMoments/g/m/lease/photo.jpg';
    await media.save(path, Buffer.from('abc')); await media.save(path, Buffer.from('abc'));
    assert.equal(calls, 1);
    await assert.rejects(media.save(path, Buffer.from('xyz')), { code: 'already-exists' });
    await assert.rejects(media.save('../outside', Buffer.from('abc')), { code: 'invalid-argument' });
  } finally { cloudinary.uploader.upload_stream = original; }
});
test('cleanup rejects changed generation and deletes immutable asset ID; tombstone remains', async () => {
  const { media, rows } = fixture();
  const ref = media.ref('groupMoments/g/m/lease/photo.jpg');
  rows.set(ref.key, { name: 'groupMoments/g/m/lease/photo.jpg', publicId: 'hobbytracker-moments-v1/a', generation: 'original', assetId: 'asset-one' });
  await assert.rejects(media.remove({ name: 'groupMoments/g/m/lease/photo.jpg', generation: 'changed' }));
  const old = cloudinary.api.delete_resources_by_asset_ids;
  cloudinary.api.delete_resources_by_asset_ids = async ids => { assert.deepEqual(ids, ['asset-one']); return { deleted: { 'asset-one': 'deleted' } }; };
  try { await media.remove({ name: 'groupMoments/g/m/lease/photo.jpg', generation: 'original' }); assert.equal(rows.get(ref.key).deleted, true); }
  finally { cloudinary.api.delete_resources_by_asset_ids = old; }
});
test('media reads fail closed on missing/deleted paths and unsafe namespaces', async () => {
  const { media } = fixture();
  await assert.rejects(media.source('groupMoments/g/m/lease/photo.jpg'), { code: 404 });
  await assert.rejects(media.source('../outside'), { code: 'invalid-argument' });
  await assert.rejects(media.page('other/'));
});
test('authenticated download URL stays internal, expires quickly, and returns bytes only', async () => {
  const { media, rows } = fixture(), path = 'groupMoments/g/m/lease/photo.jpg';
  rows.set(media.ref(path).key, { publicId: 'hobbytracker-moments-v1/a' });
  const oldUrl = cloudinary.utils.private_download_url, oldFetch = globalThis.fetch;
  cloudinary.utils.private_download_url = (publicId, format, options) => {
    assert.equal(publicId, 'hobbytracker-moments-v1/a'); assert.equal(format, 'jpg');
    assert.equal(options.type, 'authenticated');
    assert.ok(options.expires_at <= Math.floor(Date.now() / 1000) + 30);
    return 'https://api.cloudinary.com/private-test';
  };
  globalThis.fetch = async url => { assert.equal(url, 'https://api.cloudinary.com/private-test'); return new Response(Buffer.from('abc')); };
  try { assert.deepEqual(await media.source(path), Buffer.from('abc')); }
  finally { cloudinary.utils.private_download_url = oldUrl; globalThis.fetch = oldFetch; }
});
