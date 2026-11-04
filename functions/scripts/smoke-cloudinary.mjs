// Creates and removes ONLY this run's generated 32px test asset. No user/group records.
import { randomUUID } from 'node:crypto';
import sharp from 'sharp';
import { v2 as cloudinary } from 'cloudinary';
import { configureCloudinary } from '../lib/cloudinary_media.js';

configureCloudinary();
const publicId = `hobbytracker-moments-smoke/${randomUUID()}`;
const checks = { authenticatedUpload: false, privateDownload: false, cleanup: false };
const diagnostics = {};
let assetId;
try {
  const bytes = await sharp({ create: { width: 32, height: 32, channels: 3, background: '#087f72' } }).jpeg().toBuffer();
  const result = await new Promise((resolve, reject) => {
    cloudinary.uploader.upload_stream({ public_id: publicId, type: 'authenticated', resource_type: 'image',
      overwrite: false, format: 'jpg', timeout: 60_000 }, (error, value) => error ? reject(error) : resolve(value)).end(bytes);
  });
  assetId = result.asset_id;
  checks.authenticatedUpload = result.type === 'authenticated' && result.public_id === publicId;
  const url = cloudinary.utils.private_download_url(publicId, 'jpg', { type: 'authenticated',
    resource_type: 'image', expires_at: Math.floor(Date.now() / 1000) + 30 });
  const response = await fetch(url, { signal: AbortSignal.timeout(20_000), redirect: 'error' });
  diagnostics.downloadStatus = response.status;
  if (response.ok) {
    const received = Buffer.from(await response.arrayBuffer());
    checks.privateDownload = received.length > 0 && received.length < 100_000 && (await sharp(received).metadata()).width === 32;
  }
} catch (error) {
  const status = error.http_code ?? error.error?.http_code;
  if (Number.isInteger(status)) diagnostics.httpStatus = status;
  diagnostics.errorType = error instanceof Error ? error.name : 'ProviderError';
} finally {
  try {
    if (!assetId) {
      try { assetId = (await cloudinary.api.resource(publicId, { type: 'authenticated', resource_type: 'image' })).asset_id; }
      catch (error) { if ((error.http_code ?? error.error?.http_code) !== 404) throw error; }
    }
    if (assetId) {
      const deleted = await cloudinary.api.delete_resources_by_asset_ids([assetId], { invalidate: true });
      const states = Object.values(deleted.deleted ?? {});
      checks.cleanup = states.length === 1 && ['deleted', 'not_found'].includes(states[0]);
    } else checks.cleanup = true;
  } catch { diagnostics.cleanupFailed = true; }
  console.log(JSON.stringify({ checkedAt: new Date().toISOString(), checks, diagnostics, userDataUsed: false }));
  if (!Object.values(checks).every(Boolean)) process.exitCode = 2;
}
