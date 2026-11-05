import { before, beforeEach, after, test } from 'node:test';
import fs from 'node:fs';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, setDoc, updateDoc } from 'firebase/firestore';

let env;
const projectId = 'demo-hobby-admin';
before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: fs.readFileSync(new URL('../../integration/firebase/firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/alice'), {
      role: 'user', displayName: 'Alice', createdAt: new Date('2026-01-01T00:00:00Z'),
    });
  });
});
after(async () => { if (env) await env.cleanup(); });

// For actual serverTimestamp rule validation, use serverTimestamp() on writes.
import { serverTimestamp } from 'firebase/firestore';

test('owner can create and read own profile', async () => {
  const db = env.authenticatedContext('new-user').firestore();
  const ref = doc(db, 'users/new-user');
  await assertSucceeds(setDoc(ref, {
    role: 'user', displayName: 'Alice', createdAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(ref));
});

test('anonymous cannot read or write profile', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'users/alice')));
  await assertFails(setDoc(doc(db, 'users/anon'), {
    role: 'user', displayName: 'Bad', createdAt: serverTimestamp(),
  }));
});

test('other account cannot read or overwrite profile', async () => {
  const db = env.authenticatedContext('bob').firestore();
  await assertFails(getDoc(doc(db, 'users/alice')));
  await assertFails(setDoc(doc(db, 'users/alice'), {
    role: 'user', displayName: 'Bob', createdAt: serverTimestamp(),
  }));
});

test('owner cannot give self admin role or delete/create other records', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(updateDoc(doc(db, 'users/alice'), {role: 'admin'}));
  await assertFails(setDoc(doc(db, 'users/alice'), {
    role: 'admin', displayName: 'Alice', createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db, 'hobbies/my-hobby'), {title: 'Not implemented'}));
});

test('owner may update display name only', async () => {
  const ref = doc(env.authenticatedContext('alice').firestore(), 'users/alice');
  await assertSucceeds(updateDoc(ref, { displayName: 'New name' }));
  await assertFails(updateDoc(ref, { createdAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { password: 'never-store' }));
});
test('list, delete and nested collections denied', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(getDocs(collection(db, 'users')));
  await assertFails(deleteDoc(doc(db, 'users/alice')));
  await assertFails(getDoc(doc(db, 'users/alice/privateSecrets/one')));
  await assertFails(setDoc(doc(db, 'users/alice/privateSecrets/one'), { name: 'Denied' }));
});
test('other account cannot update or delete owner profile', async () => {
  const ref = doc(env.authenticatedContext('bob').firestore(), 'users/alice');
  await assertFails(updateDoc(ref, { displayName: 'Bob' }));
  await assertFails(deleteDoc(ref));
});
test('create validates schema, role, name and server time', async () => {
  const ref = doc(env.authenticatedContext('new-user').firestore(), 'users/new-user');
  const valid = { role: 'user', displayName: 'New', createdAt: serverTimestamp() };
  for (const mutation of [
    { role: 'admin' }, { role: 'staff' }, { displayName: '' },
    { displayName: 'x'.repeat(81) }, { displayName: 5 },
    { password: 'never-store' }, { createdAt: new Date('2000-01-01') },
  ]) await assertFails(setDoc(ref, { ...valid, ...mutation }));
  await assertFails(setDoc(ref, { role: 'user', displayName: 'Missing timestamp' }));
});
test('update rejects invalid display names', async () => {
  const ref = doc(env.authenticatedContext('alice').firestore(), 'users/alice');
  for (const displayName of ['', 'x'.repeat(81), 123, null]) {
    await assertFails(updateDoc(ref, { displayName }));
  }
});
