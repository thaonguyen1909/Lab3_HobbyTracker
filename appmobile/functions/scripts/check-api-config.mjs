// Read-only readiness probe. Never prints credentials, URLs or SDK error bodies.
import { applicationDefault, initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { v2 as cloudinary } from 'cloudinary';
import { configureCloudinary } from '../lib/cloudinary_media.js';

const projectId = 'hobbytracker-6ace6';
if (process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('Remove emulator overrides first.');
const checks = {};
const diagnostics = {};
let app;
try {
  configureCloudinary();
  try { checks.cloudinary = (await cloudinary.api.ping()).status === 'ok'; }
  catch (error) {
    checks.cloudinary = false;
    const status = error.http_code ?? error.error?.http_code;
    if (Number.isInteger(status)) diagnostics.cloudinaryHttpStatus = status;
    if (typeof error.code === 'string' && /^E[A-Z_]+$/.test(error.code)) diagnostics.cloudinaryNetworkCode = error.code;
  }
  app = initializeApp({ projectId, credential: applicationDefault() });
  const db = getFirestore(app);
  try { await db.doc('momentMaintenance/cleanup').get(); checks.firestore = true; }
  catch { checks.firestore = false; }
  try {
    await db.collection('momentOutbox').where('done', '==', false)
      .where('nextAttemptAt', '<=', Timestamp.now()).orderBy('nextAttemptAt').limit(1).get();
    checks.outboxQuery = true;
  } catch (error) {
    checks.outboxQuery = false;
    if (Number.isInteger(error.code)) diagnostics.outboxQueryCode = error.code;
  }
  try { await getAuth(app).getUser('moments-readiness-no-such-user'); checks.authLookup = true; }
  catch (error) { checks.authLookup = error.code === 'auth/user-not-found'; }
  await db.terminate();
  console.log(JSON.stringify({ projectId, checks, diagnostics, readOnly: true, liveUploadTested: false }));
  if (Object.values(checks).some(value => !value)) process.exitCode = 2;
} catch {
  console.error('Readiness configuration failed. Check local credentials; no secret details printed.');
  process.exitCode = 1;
} finally { if (app) await deleteApp(app); }
