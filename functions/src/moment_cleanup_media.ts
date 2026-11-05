import { getStorage } from 'firebase-admin/storage';

export interface CleanupObject { name: string; generation: string; createdAt: number; }
export interface CleanupMedia {
  page(prefix: string, token?: string): Promise<{ files: CleanupObject[]; next?: string }>;
  remove(file: CleanupObject): Promise<void>;
}

// Match generated leaves only; never use a document's arbitrary mediaPath for deletion.
export function cleanupObjectPath(name: string): boolean {
  return /^momentStaging\/[^/]{1,128}\/[A-Za-z0-9_-]{1,128}\/source$/.test(name) ||
    /^groupMoments\/[A-Za-z0-9_-]{1,128}\/[A-Za-z0-9_-]{1,128}\/[A-Za-z0-9_-]{1,128}\/(photo|thumb)\.jpg$/.test(name);
}

export class MomentCleanupMedia implements CleanupMedia {
  private readonly bucket;
  constructor(bucketName: string) { this.bucket = getStorage().bucket(bucketName); }
  async page(prefix: string, token?: string) {
    if (prefix !== 'momentStaging/' && prefix !== 'groupMoments/' &&
      !/^momentStaging\/[^/]{1,128}\/[A-Za-z0-9_-]{1,128}\/$/.test(prefix) &&
      !/^groupMoments\/[A-Za-z0-9_-]{1,128}\/[A-Za-z0-9_-]{1,128}\/$/.test(prefix)) {
      throw new Error('Cleanup prefix is outside the generated moment namespaces.');
    }
    const [files, next] = await this.bucket.getFiles({ prefix, autoPaginate: false, maxResults: 50, pageToken: token });
    return { files: files.map(file => ({ name: file.name, generation: String(file.metadata.generation ?? ''),
      createdAt: Date.parse(file.metadata.timeCreated ?? '') })), next: next?.pageToken };
  }
  async remove(file: CleanupObject): Promise<void> {
    if (!cleanupObjectPath(file.name) || !/^\d+$/.test(file.generation)) throw new Error('Unsafe cleanup object.');
    // The emulator currently ignores generation preconditions on DELETE. Check
    // stale listings explicitly too; cloud preconditions still close the IO race.
    let current;
    try { [current] = await this.bucket.file(file.name).getMetadata(); }
    catch (error) { if (Number((error as { code?: number }).code) === 404) return; throw error; }
    if (String(current.generation) !== file.generation) {
      throw Object.assign(new Error('Cleanup object generation changed.'), { code: 412 });
    }
    // Target the listed generation. A later replacement is never removed by this request.
    await this.bucket.file(file.name, { generation: file.generation,
      preconditionOpts: { ifGenerationMatch: file.generation } }).delete({ ignoreNotFound: true });
  }
}
