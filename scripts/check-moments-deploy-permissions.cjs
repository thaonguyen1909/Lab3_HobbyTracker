// Read-only IAM introspection. Never prints CLI tokens or SDK error bodies.
const fs = require('node:fs');
const path = require('node:path');
async function main() {
  const projectId = 'hobbytracker-6ace6', repo = path.resolve(__dirname, '..');
  const root = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
  const auth = require(path.join(root, 'auth'));
  const account = auth.selectAccount(undefined, repo);
  if (!account) throw new Error('No CLI account.');
  await require(path.join(root, 'requireAuth')).requireAuth({ project: projectId, nonInteractive: true,
    user: account.user, tokens: account.tokens });
  const { Client } = require(path.join(root, 'apiv2'));
  const client = new Client({ urlPrefix: 'https://cloudresourcemanager.googleapis.com', apiVersion: 'v1' });
  const requested = ['serviceusage.services.use', 'serviceusage.services.get',
    'firebaserules.rulesets.create', 'firebaserules.releases.update', 'firebaserules.releases.create',
    'datastore.indexes.create', 'datastore.indexes.list'];
  // testIamPermissions is a read-only API despite using HTTP POST.
  const result = await client.post(`/projects/${projectId}:testIamPermissions`, { permissions: requested }, {
    resolveOnHTTPError: true, skipLog: { resBody: true }, timeout: 20000 });
  const granted = result.body.permissions ?? [];
  const facts = { checkedAt: new Date().toISOString(), projectId, account: account.user.email,
    httpStatus: result.status, readOnly: true,
    permissions: Object.fromEntries(requested.map(permission => [permission, granted.includes(permission)])) };
  if (result.status !== 200) delete facts.permissions;
  fs.writeFileSync(path.join(repo, 'docs/evidence/07b/cloudinary-retest/deploy-permissions.json'), JSON.stringify(facts, null, 2));
  console.log(JSON.stringify(facts));
  if (result.status !== 200 || granted.length !== requested.length) process.exitCode = 2;
}
main().catch(() => { console.error('Permission probe failed; no credential details printed.'); process.exitCode = 1; });
