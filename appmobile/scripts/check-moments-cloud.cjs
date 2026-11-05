// Read-only cloud preflight. Uses the Firebase CLI's authenticated account;
// never prints tokens, upgrades billing, enables APIs or deploys resources.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const projectId = 'hobbytracker-6ace6';
const bucketName = 'hobbytracker-6ace6.firebasestorage.app';
const repo = path.resolve(__dirname, '..');
const cliRoot = process.env.APPDATA && path.join(process.env.APPDATA, 'npm', 'node_modules', 'firebase-tools');
const hash = value => crypto.createHash('sha256').update(value).digest('hex');

async function main() {
  const args = process.argv.slice(2);
  if (args.some(arg => arg !== '--snapshot-rules')) throw new Error('Only --snapshot-rules is supported. Target project/bucket are fixed.');
  if (process.versions.node.split('.')[0] !== '22') throw new Error('Use Node 22 to match the Functions runtime.');
  if (!cliRoot || !fs.existsSync(path.join(cliRoot, 'lib', 'auth.js'))) throw new Error('Install the Firebase CLI globally first.');
  const native = JSON.parse(fs.readFileSync(path.join(repo, 'android/app/google-services.json'), 'utf8'));
  if (native.project_info?.project_id !== projectId || native.project_info?.storage_bucket !== bucketName) {
    throw new Error('Native Firebase configuration does not match the approved target. No cloud requests made.');
  }
  if (process.env.FIREBASE_TOKEN || process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_STORAGE_EMULATOR_HOST || process.env.FUNCTIONS_EMULATOR) {
    throw new Error('Remove token/emulator overrides from this process before a cloud preflight.');
  }
  const auth = require(path.join(cliRoot, 'lib/auth'));
  const { requireAuth } = require(path.join(cliRoot, 'lib/requireAuth'));
  const { Client } = require(path.join(cliRoot, 'lib/apiv2'));
  const account = auth.selectAccount(undefined, repo);
  if (!account) throw new Error('Sign in with firebase login:add and select the project account first.');
  await requireAuth({ project: projectId, nonInteractive: true, user: account.user, tokens: account.tokens });
  const get = (origin, version, resource) => new Client({ urlPrefix: origin, apiVersion: version }).get(resource,
    { resolveOnHTTPError: true, timeout: 20000, skipLog: { resBody: true } });
  const facts = { checkedAt: new Date().toISOString(), projectId, bucketName, region: 'asia-southeast1',
    cliVersion: JSON.parse(fs.readFileSync(path.join(cliRoot, 'package.json'), 'utf8')).version,
    status: 'BLOCKED', cloudMutations: false, blockers: [], checks: [], sourceHashes: {} };
  const add = (check, response, details = {}) => facts.checks.push({ check, httpStatus: response.status,
    ...details, ...(response.body?.error ? { reason: response.body.error.status ?? 'API_ERROR' } : {}) });
  const project = await get('https://firebase.googleapis.com', 'v1beta1', `/projects/${projectId}`);
  add('project', project, { state: project.body.state });
  if (project.status !== 200) facts.blockers.push('PROJECT_ACCESS_UNAVAILABLE');
  if (project.status === 200 && project.body.projectId === projectId) {
    const billing = await get('https://cloudbilling.googleapis.com', 'v1', `/projects/${projectId}/billingInfo`);
    add('billing', billing, { enabled: billing.body.billingEnabled === true });
    const bucket = await get('https://storage.googleapis.com', 'storage/v1', `/b/${bucketName}`);
    add('bucket', bucket, { exists: bucket.status === 200, location: bucket.body.location,
      softDeleteRetentionSeconds: bucket.body.softDeletePolicy?.retentionDurationSeconds });
    if (billing.status !== 200) facts.blockers.push('BILLING_STATE_UNAVAILABLE');
    else if (billing.body.billingEnabled !== true) facts.blockers.push('BILLING_NOT_ENABLED');
    if (bucket.status !== 200) facts.blockers.push(bucket.status === 404 ? 'STORAGE_BUCKET_NOT_FOUND' : 'STORAGE_BUCKET_UNAVAILABLE');
    facts.status = billing.status === 200 && billing.body.billingEnabled === true && bucket.status === 200
      ? 'INFRASTRUCTURE_CHECKED' : 'BLOCKED';
    if (args.includes('--snapshot-rules')) {
      const targetDir = path.join(repo, 'deployment-artifacts', `moments-${Date.now()}`);
      fs.mkdirSync(targetDir, { recursive: true });
      for (const [name, release] of [['firestore', 'cloud.firestore'], ['storage', `firebase.storage/${bucketName}`]]) {
        const active = await get('https://firebaserules.googleapis.com', 'v1', `/projects/${projectId}/releases/${release}`);
        if (active.status !== 200) { add(`${name}Rules`, active, { snapshotSaved: false }); continue; }
        const ruleset = active.body.rulesetName;
        const allowed = [projectId, String(project.body.projectNumber)];
        if (typeof ruleset !== 'string' || !allowed.some(id => ruleset.startsWith(`projects/${id}/rulesets/`)) ||
            !/^projects\/[^/]+\/rulesets\/[A-Za-z0-9_-]+$/.test(ruleset)) throw new Error('Unexpected ruleset target.');
        const source = await get('https://firebaserules.googleapis.com', 'v1', `/${ruleset}`);
        const files = source.body.source?.files;
        if (source.status !== 200 || !Array.isArray(files)) { add(`${name}Rules`, source, { snapshotSaved: false }); continue; }
        fs.writeFileSync(path.join(targetDir, `${name}-ruleset.json`), JSON.stringify({ release: active.body, source: files }, null, 2));
        const content = files.map(file => file.content ?? '').join('\n');
        const local = fs.readFileSync(path.join(repo, 'firebase', `${name}.rules`), 'utf8');
        add(`${name}Rules`, source, { snapshotSaved: true, remoteSha256: hash(content),
          localSha256: hash(local), differsFromLocal: hash(content) !== hash(local) });
      }
      facts.backupDirectory = path.relative(repo, targetDir).replaceAll('\\', '/');
    }
  }
  for (const file of ['firebase.json', 'firebase/firestore.rules', 'firebase/storage.rules', 'firebase/firestore.indexes.json',
    'functions/package.json', 'functions/package-lock.json', 'functions/src/index.ts']) {
    facts.sourceHashes[file] = hash(fs.readFileSync(path.join(repo, file)));
  }
  const collectSource = directory => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const file = path.join(directory, entry.name);
      if (entry.isDirectory()) collectSource(file);
      else if (entry.isFile() && entry.name.endsWith('.ts')) {
        facts.sourceHashes[path.relative(repo, file).replaceAll('\\', '/')] = hash(fs.readFileSync(file));
      }
    }
  };
  collectSource(path.join(repo, 'functions/src'));
  const directory = path.join(repo, 'docs/evidence/07b/moments-cloud');
  fs.mkdirSync(directory, { recursive: true });
  fs.writeFileSync(path.join(directory, 'preflight.json'), JSON.stringify(facts, null, 2));
  console.log(JSON.stringify(facts, null, 2));
  // An infrastructure check is not a deployment or smoke-test approval.
  process.exitCode = facts.status === 'BLOCKED' ? 2 : 0;
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
