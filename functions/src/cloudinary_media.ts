import { createHash, randomUUID } from 'node:crypto';
import { v2 as cloudinary } from 'cloudinary';
import type { UploadApiResponse } from 'cloudinary';
import type { Firestore, DocumentData } from 'firebase-admin/firestore';
import { cleanupObjectPath, type CleanupMedia, type CleanupObject } from './moment_cleanup_media.js';
import { MAX_UPLOAD_BYTES, MomentError } from './domain.js';

const ROOT = 'hobbytracker-moments-v1/';
export function configureCloudinary() {
  const { CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET } = process.env;
  if (!CLOUDINARY_CLOUD_NAME || !CLOUDINARY_API_KEY || !CLOUDINARY_API_SECRET ||
      !/^[a-z0-9_-]+$/.test(CLOUDINARY_CLOUD_NAME) ||
      [CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET].some(value => value.startsWith('REPLACE'))) {
    throw new Error('Configure Cloudinary credentials in the server environment.');
  }
  cloudinary.config({ cloud_name: CLOUDINARY_CLOUD_NAME, api_key: CLOUDINARY_API_KEY,
    api_secret: CLOUDINARY_API_SECRET, secure: true });
}

/** No CDN URLs cross the API boundary. Authenticated originals and thumbnails only. */
export class CloudinaryMedia implements CleanupMedia {
  readonly bucketName = 'cloudinary'; // Legacy ticket field, not a Firebase bucket.
  constructor(private readonly db: Firestore) {}
  private ref(name: string) {
    if (!cleanupObjectPath(name)) throw new MomentError('invalid-argument', 'Invalid media path.');
    return this.db.doc(`momentCloudAssets/${createHash('sha256').update(name).digest('hex')}`);
  }
  async save(name: string, bytes: Buffer): Promise<void> {
    if (!bytes.length || bytes.length > MAX_UPLOAD_BYTES) throw new MomentError('invalid-argument', 'Invalid image size.');
    const ref = this.ref(name), hash = createHash('sha256').update(bytes).digest('hex');
    const asset: DocumentData = await this.db.runTransaction(async tx => {
      const old = (await tx.get(ref)).data();
      if (old) {
        if (old.hash !== hash || old.deleted) throw new MomentError('already-exists', 'Media cannot be replaced.');
        return old;
      }
      const data = { name, hash, publicId: ROOT + randomUUID(), generation: randomUUID(), createdAt: Date.now() };
      tx.create(ref, data); return data;
    });
    if (asset.assetId) return;
    const result = await new Promise<UploadApiResponse>((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream({ public_id: asset.publicId, type: 'authenticated',
        resource_type: 'image', format: 'jpg', overwrite: false, timeout: 60_000 },
      (error, response) => error ? reject(error) : response ? resolve(response) : reject(new Error('Missing upload result.')));
      stream.end(bytes);
    });
    if (result.type !== 'authenticated' || result.public_id !== asset.publicId || result.resource_type !== 'image') {
      throw new Error('Unexpected Cloudinary upload result.');
    }
    await ref.update({ assetId: result.asset_id, bytes: result.bytes });
  }
  async source(name: string): Promise<Buffer> {
    const asset = (await this.ref(name).get()).data();
    if (!asset || asset.deleted) throw Object.assign(new Error('Missing media.'), { code: 404 });
    if (!String(asset.publicId).startsWith(ROOT)) throw new Error('Unsafe asset.');
    // Expiring download URL is used inside this server only; never stored or logged.
    const url = cloudinary.utils.private_download_url(asset.publicId, 'jpg', {
      type: 'authenticated', resource_type: 'image', expires_at: Math.floor(Date.now() / 1000) + 30,
    });
    const response = await fetch(url, { signal: AbortSignal.timeout(20_000), redirect: 'error' });
    if (!response.ok) throw Object.assign(new Error('Media download unavailable.'), { code: response.status });
    const chunks: Uint8Array[] = []; let size = 0;
    for await (const chunk of response.body!) {
      size += chunk.length;
      if (size > MAX_UPLOAD_BYTES) throw new Error('Media size exceeded.');
      chunks.push(chunk);
    }
    if (!size) throw new Error('Empty media.');
    return Buffer.concat(chunks);
  }
  async page(prefix: string, token?: string) {
    if (prefix !== 'momentStaging/' && prefix !== 'groupMoments/' &&
      !/^momentStaging\/[^/]{1,128}\/[A-Za-z0-9_-]{1,128}\/$/.test(prefix) &&
      !/^groupMoments\/[A-Za-z0-9_-]{1,128}\/[A-Za-z0-9_-]{1,128}\/$/.test(prefix)) throw new Error('Unsafe prefix.');
    let query = this.db.collection('momentCloudAssets').where('name', '>=', prefix)
      .where('name', '<', prefix + '\uf8ff').orderBy('name').limit(50);
    if (token) query = query.startAfter(token);
    const docs = await query.get();
    return { files: docs.docs.filter(doc => !doc.data().deleted).map(doc => {
      const data = doc.data(); return { name: data.name as string, generation: data.generation as string, createdAt: data.createdAt as number };
    }), next: docs.size === 50 ? docs.docs.at(-1)!.data().name as string : undefined };
  }
  async remove(value: string | CleanupObject): Promise<void> {
    const name = typeof value === 'string' ? value : value.name, ref = this.ref(name);
    const asset = (await ref.get()).data();
    if (!asset || asset.deleted) return;
    if (typeof value !== 'string' && value.generation !== asset.generation) throw new Error('Asset generation changed.');
    if (!String(asset.publicId).startsWith(ROOT)) throw new Error('Unsafe asset.');
    let assetId = asset.assetId as string | undefined;
    if (!assetId) {
      try { assetId = (await cloudinary.api.resource(asset.publicId, { type: 'authenticated', resource_type: 'image' })).asset_id; }
      catch (error) {
        const e = error as { http_code?: number; error?: { http_code?: number } };
        if ((e.http_code ?? e.error?.http_code) !== 404) throw error;
      }
    }
    if (assetId) {
      const result = await cloudinary.api.delete_resources_by_asset_ids([assetId], { invalidate: true });
      const deleted = (result as unknown as { deleted?: Record<string, string> }).deleted;
      const states = Object.values(deleted ?? {});
      if (states.length !== 1 || !['deleted', 'not_found'].includes(states[0])) throw new Error('Asset deletion not confirmed.');
    }
    // Retain a tombstone: a path can never later be overwritten or resurrected.
    await ref.update({ deleted: true });
  }
}
