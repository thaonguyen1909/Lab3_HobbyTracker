import { createHash } from 'node:crypto';

export const LIFETIME_MS = 3 * 60 * 60 * 1000;
export const UPLOAD_WINDOW_MS = 10 * 60 * 1000;
export const MAX_UPLOAD_BYTES = 5 * 1024 * 1024;
export const MAX_PHOTO_BYTES = 2 * 1024 * 1024;
export const MAX_THUMBNAIL_BYTES = 200 * 1024;
export const PROCESSING_LEASE_MS = 150_000;

export type ErrorCode = 'unauthenticated' | 'invalid-argument' | 'permission-denied'
  | 'not-found' | 'already-exists' | 'failed-precondition' | 'deadline-exceeded'
  | 'aborted' | 'resource-exhausted' | 'unavailable';

export class MomentError extends Error {
  constructor(readonly code: ErrorCode, message: string) {
    super(message);
    this.name = 'MomentError';
  }
}

export function requireUid(uid: string | undefined): string {
  if (!uid) throw new MomentError('unauthenticated', 'Sign in to use moments.');
  // Firebase UID is trusted auth context, never a caller-supplied authorId.
  if (uid.length > 128 || uid.includes('/')) {
    throw new MomentError('permission-denied', 'Unsupported account identifier.');
  }
  return uid;
}

export function record(input: unknown, required: string[], optional: string[] = []): Record<string, unknown> {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new MomentError('invalid-argument', 'Expected a request object.');
  }
  const value = input as Record<string, unknown>;
  if (required.some(key => !(key in value)) ||
      Object.keys(value).some(key => ![...required, ...optional].includes(key))) {
    throw new MomentError('invalid-argument', 'Unexpected or missing request fields.');
  }
  return value;
}

export function id(value: unknown): string {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) {
    throw new MomentError('invalid-argument', 'Invalid identifier.');
  }
  return value;
}

export function beginInput(input: unknown) {
  const value = record(input, ['requestId', 'groupId', 'hobbyId', 'caption']);
  if (typeof value.caption !== 'string' || [...value.caption.trim()].length > 160) {
    throw new MomentError('invalid-argument', 'Caption must be at most 160 characters.');
  }
  return {
    requestId: id(value.requestId), groupId: id(value.groupId),
    hobbyId: id(value.hobbyId), caption: value.caption.trim(),
  };
}

export function stableMomentId(uid: string, requestId: string): string {
  return createHash('sha256').update(JSON.stringify([uid, requestId])).digest('hex').slice(0, 40);
}

export function listInput(input: unknown) {
  const value = record(input, ['groupId'], ['limit', 'cursor']);
  const limit = value.limit ?? 20;
  if (!Number.isInteger(limit) || (limit as number) < 1 || (limit as number) > 20) {
    throw new MomentError('invalid-argument', 'Limit must be between 1 and 20.');
  }
  let cursor: { expiresAtMs: number; momentId: string } | undefined;
  if (value.cursor !== undefined) {
    const raw = record(value.cursor, ['expiresAtMs', 'momentId']);
    if (!Number.isSafeInteger(raw.expiresAtMs) || (raw.expiresAtMs as number) <= 0 ||
        (raw.expiresAtMs as number) > Date.parse('9999-12-31T23:59:59.999Z')) {
      throw new MomentError('invalid-argument', 'Invalid cursor.');
    }
    cursor = { expiresAtMs: raw.expiresAtMs as number, momentId: id(raw.momentId) };
  }
  return { groupId: id(value.groupId), limit: limit as number, cursor };
}
