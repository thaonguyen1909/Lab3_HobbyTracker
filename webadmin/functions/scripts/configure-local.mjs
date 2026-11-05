import {writeFile} from 'node:fs/promises';
import {applicationDefault, initializeApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';

const projectId = process.env.GOOGLE_CLOUD_PROJECT;
if (!projectId || !process.env.GOOGLE_APPLICATION_CREDENTIALS) throw new Error('Missing local server configuration.');
const credential = applicationDefault();
initializeApp({projectId, credential});
const {access_token} = await credential.getAccessToken();
async function management(path) {
  const response = await fetch(`https://firebase.googleapis.com/v1beta1/projects/${projectId}/${path}`, {
    headers: {Authorization: `Bearer ${access_token}`},
  });
  if (!response.ok) throw new Error(`Firebase management request failed: ${response.status}`);
  return response.json();
}
let {apps = []} = await management('webApps');
if (!apps.length) {
  const response = await fetch(`https://firebase.googleapis.com/v1beta1/projects/${projectId}/webApps`, {
    method:'POST', headers:{Authorization:`Bearer ${access_token}`, 'Content-Type':'application/json'},
    body:JSON.stringify({displayName:'Hobby Tracker Admin Web'}),
  });
  if (!response.ok) throw new Error(`Web app registration failed: ${response.status}`);
  const operation = await response.json();
  for (let attempt=0; attempt<20; attempt++) {
    const result = await fetch(`https://firebase.googleapis.com/v1beta1/${operation.name}`, {headers:{Authorization:`Bearer ${access_token}`}}).then(r=>r.json());
    if (result.error) throw new Error(`Web app registration error: ${result.error.code}`);
    if (result.done) break;
    await new Promise(resolve=>setTimeout(resolve, 1000));
  }
  ({apps = []} = await management('webApps'));
  if (!apps.length) throw new Error('Web app registration is still pending. Run setup again.');
}
const firebase = await management(`webApps/${encodeURIComponent(apps[0].appId)}/config`);
const publicConfig = Object.fromEntries(['apiKey','authDomain','projectId','appId','storageBucket'].filter(key => firebase[key]).map(key => [key, firebase[key]]));
await writeFile(new URL('../../public/firebase-connection.local.json', import.meta.url), JSON.stringify({apiUrl:'http://127.0.0.1:8788', firebase:publicConfig}, null, 2));
const staff = await getFirestore().collection('adminStaff').where('status','==','active').limit(10).get();
const authResponse = await fetch(`https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`, {headers:{Authorization:`Bearer ${access_token}`}});
const authConfig = authResponse.ok ? await authResponse.json() : null;
console.log(JSON.stringify({projectId, webConfigPrepared:true, activeAdminCountUpTo10:staff.size,
  localhostAuthorized:authConfig?.authorizedDomains?.includes('localhost') ?? null,
  loopbackAuthorized:authConfig?.authorizedDomains?.includes('127.0.0.1') ?? null}));
