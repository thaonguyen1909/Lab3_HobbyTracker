import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

const exec = promisify(execFile), script = new URL('../scripts/cleanup-local.mjs',import.meta.url);
test('local cleanup CLI refuses missing or non-loopback emulator hosts before SDK initialization',async()=>{
  for (const host of ['', 'firestore.googleapis.com:443']) {
    await assert.rejects(exec(process.execPath,[script.pathname.replace(/^\/([A-Za-z]:\/)/,'$1')],{
      env:{...process.env,FIRESTORE_EMULATOR_HOST:host,FIREBASE_STORAGE_EMULATOR_HOST:'127.0.0.1:9199'},timeout:15_000}),
      error=>String(error.stderr).includes('Cloud execution is forbidden'));
  }
});
test('local CLI preview does not mutate metadata/files; --run performs one real bounded cleanup',async()=>{
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_STORAGE_EMULATOR_HOST) throw new Error('Demo emulators required.');
  const projectId='demo-hobbytracker-moments',app=initializeApp({projectId,storageBucket:`${projectId}.appspot.com`},'cleanup-cli-test');
  try {
    const db=getFirestore(app),bucket=getStorage(app).bucket(), path='groupMoments/cli/cli_expired/cli/photo.jpg';
    const ref=db.doc('groups/cli/moments/cli_expired'), before=Date.now()-1000;
    await ref.set({status:'ready',authorId:'cli-test',caption:'test-only cleanup fixture',expiresAt:Timestamp.fromMillis(before),cleanupPending:true,cleanupAfter:Timestamp.fromMillis(before)});
    await bucket.file(path).save(Buffer.from('test-only cleanup bytes'));
    const nativePath = (await import('node:url')).fileURLToPath(script);
    const preview=JSON.parse((await exec(process.execPath,[nativePath],{timeout:30_000})).stdout.trim());
    assert.equal(preview.mode,'preview');assert.equal((await ref.get()).data().caption,'test-only cleanup fixture');
    assert.equal((await bucket.file(path).exists())[0],true);
    const run=JSON.parse((await exec(process.execPath,[nativePath,'--run'],{timeout:30_000})).stdout.trim());
    assert.equal(run.mode,'run');assert.equal(run.result.errors,0);
    assert.equal((await bucket.file(path).exists())[0],false);assert.equal((await ref.get()).data().caption,undefined);
  } finally { await deleteApp(app); }
});
