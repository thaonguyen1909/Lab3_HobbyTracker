import type { IncomingMessage, ServerResponse } from 'node:http';
import { MomentError, MAX_UPLOAD_BYTES } from './domain.js';
import type { MomentService } from './moments.js';

const operations = {
  beginGroupMomentUpload: 'begin', publishGroupMoment: 'publish', listGroupMoments: 'list',
  getGroupMoment: 'get', getGroupMomentImage: 'image', retractGroupMoment: 'retract',
} as const;
type VerifyToken = (token: string) => Promise<{ uid: string }>;
async function body(request: IncomingMessage, limit: number) {
  if (Number(request.headers['content-length'] ?? 0) > limit) throw new MomentError('invalid-argument', 'Request too large.');
  const chunks: Buffer[] = []; let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > limit) throw new MomentError('invalid-argument', 'Request too large.');
    chunks.push(Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
}
const statuses: Record<string, number> = { unauthenticated: 401, 'permission-denied': 403,
  'not-found': 404, 'invalid-argument': 400, 'resource-exhausted': 429, aborted: 409,
  'already-exists': 409, 'failed-precondition': 409, 'deadline-exceeded': 408 };

export function momentsHttp(service: MomentService, verify: VerifyToken) {
  let active = 0;
  return async (request: IncomingMessage, response: ServerResponse) => {
    response.setHeader('Cache-Control', 'private, no-store, max-age=0');
    response.setHeader('Content-Type', 'application/json; charset=utf-8');
    response.setHeader('X-Content-Type-Options', 'nosniff');
    const reply = (status: number, value: unknown) => { response.writeHead(status); response.end(JSON.stringify(value)); };
    if (request.method === 'GET' && request.url === '/health') { reply(200, { status: 'ok' }); return; }
    if (active >= 4) { reply(429, { error: { code: 'resource-exhausted', message: 'Server busy. Retry shortly.' } }); return; }
    active++;
    try {
      const url = new URL(request.url ?? '/', 'http://localhost');
      if (request.method !== 'POST' || !url.pathname.startsWith('/v1/')) throw new MomentError('not-found', 'Unknown endpoint.');
      const method = url.pathname.slice(4);
      if (!(Object.hasOwn(operations, method) || method === 'stage')) throw new MomentError('not-found', 'Unknown endpoint.');
      const bearer = /^Bearer ([^\s]+)$/.exec(request.headers.authorization ?? '')?.[1];
      if (!bearer) throw new MomentError('unauthenticated', 'Sign in again.');
      let uid: string;
      try { uid = (await verify(bearer)).uid; }
      catch { throw new MomentError('unauthenticated', 'Sign in again.'); }
      let result: unknown;
      if (method === 'stage') {
        if (request.headers['content-type'] !== 'application/octet-stream') throw new MomentError('invalid-argument', 'Use binary image data.');
        result = await service.stage(uid, { momentId: url.searchParams.get('momentId') }, await body(request, MAX_UPLOAD_BYTES));
      } else {
        if (request.headers['content-type']?.split(';')[0].trim() !== 'application/json') throw new MomentError('invalid-argument', 'Use JSON.');
        let input: unknown;
        try { input = JSON.parse((await body(request, 16_384)).toString('utf8')); }
        catch (error) { if (error instanceof MomentError) throw error; throw new MomentError('invalid-argument', 'Invalid JSON.'); }
        result = await service[operations[method as keyof typeof operations]](uid, input);
      }
      reply(200, { data: result });
    } catch (error) {
      const failure = error instanceof MomentError ? error : new MomentError('unavailable', 'The operation could not be completed. Please retry.');
      if (!(error instanceof MomentError)) console.error('Moment API operation failed', { errorType: error instanceof Error ? error.name : 'Unknown' });
      if (!response.headersSent && !response.destroyed) reply(statuses[failure.code] ?? 503, { error: { code: failure.code, message: failure.message } });
    } finally { active--; }
  };
}
