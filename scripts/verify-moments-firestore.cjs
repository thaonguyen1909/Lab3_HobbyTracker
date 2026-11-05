// Read-only post-deploy verification. No tokens or raw Rules are printed.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
async function main() {
  const projectId = 'hobbytracker-6ace6', repo = path.resolve(__dirname, '..');
  const root = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
  const auth = require(path.join(root, 'auth')), account = auth.selectAccount(undefined, repo);
  if (!account) throw new Error('No CLI account.');
  await require(path.join(root, 'requireAuth')).requireAuth({ project: projectId, nonInteractive: true, user: account.user, tokens: account.tokens });
  const { Client } = require(path.join(root, 'apiv2'));
  const rules = new Client({ urlPrefix: 'https://firebaserules.googleapis.com', apiVersion: 'v1' });
  const firestore = new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
  const options = { skipLog: { resBody: true }, timeout: 20000 };
  const release = (await rules.get(`/projects/${projectId}/releases/cloud.firestore`, options)).body;
  if (!new RegExp(`^projects/(${projectId}|406311046578)/rulesets/[A-Za-z0-9_-]+$`).test(release.rulesetName)) throw new Error('Wrong Rules project.');
  const source = (await rules.get('/' + release.rulesetName, options)).body.source.files;
  const normalize = text => text.replace(/\r\n/g, '\n').trim();
  const local = fs.readFileSync(path.join(repo, 'firebase/firestore.rules'), 'utf8');
  const matches = source.length === 1 && normalize(source[0].content) === normalize(local);
  const base = `/projects/${projectId}/databases/(default)/collectionGroups/`;
  const remote = (await firestore.get(base + '-/indexes', options)).body.indexes ?? [];
  const specs = JSON.parse(fs.readFileSync(path.join(repo, 'firebase/firestore.indexes.json')));
  const indexes = specs.indexes.map(spec => {
    const found = remote.find(index => index.name.includes(`/collectionGroups/${spec.collectionGroup}/`) &&
      index.queryScope === spec.queryScope && spec.fields.every((field, i) =>
        index.fields?.[i]?.fieldPath === field.fieldPath && index.fields[i].order === field.order));
    return { collectionGroup: spec.collectionGroup, queryScope: spec.queryScope, state: found?.state ?? 'MISSING' };
  });
  const field = (await firestore.get(base + 'momentInbox/fields/expiresAt', options)).body;
  const expiry = field.indexConfig?.indexes?.find(index => index.queryScope === 'COLLECTION_GROUP' &&
    index.fields?.some(item => item.fieldPath === 'expiresAt' && item.order === 'ASCENDING'));
  const facts = { checkedAt: new Date().toISOString(), projectId, readOnly: true,
    rulesMatchLocal: matches, localRulesSha256: crypto.createHash('sha256').update(local).digest('hex'),
    indexes, inboxExpiryIndexState: expiry?.state ?? 'MISSING' };
  const evidencePath = process.argv.includes('--schedule')
    ? 'docs/evidence/04/quick-schedule/firestore-post-deploy.json'
    : 'docs/evidence/07b/cloudinary-retest/firestore-post-deploy.json';
  fs.writeFileSync(path.join(repo, evidencePath), JSON.stringify(facts, null, 2));
  console.log(JSON.stringify(facts));
  if (!matches || indexes.some(index => index.state !== 'READY') || expiry?.state !== 'READY') process.exitCode = 2;
}
main().catch(() => { console.error('Post-deploy read check failed; no private details printed.'); process.exitCode = 1; });
