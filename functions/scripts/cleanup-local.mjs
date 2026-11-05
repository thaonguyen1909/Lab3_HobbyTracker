import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { MomentCleanup } from '../lib/moment_cleanup.js';
import { MomentCleanupMedia } from '../lib/moment_cleanup_media.js';

// No project/bucket override and no cloud fallback, even if ADC exists on host.
if (!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST ?? '') ||
    !/^(127\.0\.0\.1|localhost):\d+$/.test(process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '')) {
  throw new Error('Set loopback Firestore and Storage emulator hosts. Cloud execution is forbidden.');
}
const projectId = 'demo-hobbytracker-moments', bucket = `${projectId}.appspot.com`;
const app = initializeApp({projectId,storageBucket:bucket});
try {
  const db = getFirestore(app), run = process.argv.includes('--run');
  if (process.argv.slice(2).some(arg => arg !== '--run')) throw new Error('Only --run is supported. No arbitrary project/path arguments.');
  if (run) console.log(JSON.stringify({projectId, mode:'run', result:await new MomentCleanup(db,new MomentCleanupMedia(bucket)).run()}));
  else {
    const docs = await db.collectionGroup('moments').where('expiresAt','<=',Timestamp.now()).limit(10).get();
    console.log(JSON.stringify({projectId,mode:'preview',expiredMetadataInSample:docs.size,sampleLimit:10,
      note:'No writes/deletes performed. Use --run for one bounded cleanup pass.'}));
  }
} finally { await deleteApp(app); }
