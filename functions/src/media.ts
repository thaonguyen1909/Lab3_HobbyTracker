import { getStorage } from 'firebase-admin/storage';
import sharp from 'sharp';
import { MAX_UPLOAD_BYTES, MAX_PHOTO_BYTES, MAX_THUMBNAIL_BYTES, MomentError } from './domain.js';

export async function normalizePhoto(bytes: Buffer): Promise<{ photo: Buffer; thumbnail: Buffer }> {
  if (bytes.length === 0 || bytes.length > MAX_UPLOAD_BYTES) {
    throw new MomentError('invalid-argument', 'Image must be between 1 byte and 5 MB.');
  }
  try {
    const options = { limitInputPixels: 24_000_000, failOn: 'error' as const };
    const metadata = await sharp(bytes, options).metadata();
    if (!['jpeg', 'png', 'webp'].includes(metadata.format ?? '') || (metadata.pages ?? 1) !== 1) {
      throw new MomentError('invalid-argument', 'Use a single JPEG, PNG or WebP image.');
    }
    // Sharp strips EXIF/GPS by default; never call withMetadata here.
    const photo = await sharp(bytes, options).rotate()
      .resize(1600, 1600, { fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 80 }).toBuffer();
    const thumbnail = await sharp(photo).resize(512, 512, { fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 65 }).toBuffer();
    if (photo.length > MAX_PHOTO_BYTES || thumbnail.length > MAX_THUMBNAIL_BYTES) {
      throw new MomentError('invalid-argument', 'Image cannot be compressed to the supported size.');
    }
    return { photo, thumbnail };
  } catch (error) {
    if (error instanceof MomentError) throw error;
    throw new MomentError('invalid-argument', 'Image bytes are invalid or dimensions are too large.');
  }
}

export class MomentMediaStore {
  private readonly bucket;
  constructor(readonly bucketName: string) {
    this.bucket = getStorage().bucket(bucketName);
  }

  async source(path: string): Promise<Buffer> {
    const file = this.bucket.file(path);
    const [metadata] = await file.getMetadata();
    const size = Number(metadata.size);
    if (!Number.isSafeInteger(size) || size < 1 || size > MAX_UPLOAD_BYTES) {
      throw new MomentError('invalid-argument', 'Invalid upload size.');
    }
    const [bytes] = await file.download();
    return bytes;
  }

  async save(path: string, bytes: Buffer): Promise<void> {
    await this.bucket.file(path).save(bytes, {
      resumable: false,
      metadata: { contentType: 'image/jpeg', cacheControl: 'private, no-store, max-age=0',
        metadata: { firebaseStorageDownloadTokens: '' } },
      preconditionOpts: { ifGenerationMatch: 0 },
    });
  }

  async remove(path: string): Promise<void> {
    await this.bucket.file(path).delete({ ignoreNotFound: true });
  }
}
