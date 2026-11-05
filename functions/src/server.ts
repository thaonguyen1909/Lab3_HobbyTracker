import { createServer } from 'node:http';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { CloudinaryMedia, configureCloudinary } from './cloudinary_media.js';
import { MomentService } from './moments.js';
import { MomentDelivery } from './moment_delivery.js';
import { MomentCleanup } from './moment_cleanup.js';
import { momentsHttp } from './moments_http.js';

const projectId = 'hobbytracker-6ace6';
if (process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST || process.env.FUNCTIONS_EMULATOR || process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
  throw new Error('Standalone server uses real Firebase. Remove emulator overrides.');
}
if (process.env.GOOGLE_CLOUD_PROJECT && process.env.GOOGLE_CLOUD_PROJECT !== projectId) throw new Error('Wrong Firebase project.');
if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) throw new Error('Configure GOOGLE_APPLICATION_CREDENTIALS with a local service-account file. Never commit it.');
configureCloudinary();
initializeApp({ projectId, credential: applicationDefault() });
const db = getFirestore(), media = new CloudinaryMedia(db);
const service = new MomentService(db, media);
const delivery = new MomentDelivery(db, process.env.MOMENTS_ENABLE_FCM === 'true' ? getMessaging() : null);
const cleanup = new MomentCleanup(db, media);
const handler = momentsHttp(service, token => getAuth().verifyIdToken(token, true));
const server = createServer((request, response) => { void handler(request, response); });
server.requestTimeout = 120_000; server.headersTimeout = 10_000; server.keepAliveTimeout = 5_000;
const port = Number(process.env.MOMENTS_PORT ?? process.env.PORT ?? 8787);
if (!Number.isInteger(port) || port < 1024 || port > 65535) throw new Error('Invalid MOMENTS_PORT.');
const host = process.env.MOMENTS_BIND ?? '127.0.0.1';
if (!['127.0.0.1', '0.0.0.0'].includes(host)) throw new Error('Invalid MOMENTS_BIND.');
let stopping = false;
const timers = new Set<NodeJS.Timeout>();
function schedule(name: string, ms: number, work: () => Promise<unknown>) {
  const timer = setTimeout(async () => {
    timers.delete(timer);
    if (stopping) return;
    try { await work(); }
    catch (error) { console.error('Moment worker failed', { worker: name, errorType: error instanceof Error ? error.name : 'Unknown' }); }
    if (!stopping) schedule(name, ms, work);
  }, ms);
  timers.add(timer);
}
server.listen(port, host, () => {
  console.log(`Moments API listening on ${host}:${port}; project=${projectId}; storage=Cloudinary; FCM=${process.env.MOMENTS_ENABLE_FCM === 'true'}`);
  // Poll the durable outbox: no Firebase Firestore trigger/Scheduler deployment needed.
  schedule('delivery', 15_000, () => delivery.retryDue());
  schedule('cleanup', 5 * 60_000, () => cleanup.run());
});
function stop() { stopping = true; timers.forEach(clearTimeout); server.close(); }
process.on('SIGINT', stop); process.on('SIGTERM', stop);
