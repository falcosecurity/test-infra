// SPDX-License-Identifier: Apache-2.0
import assert from 'node:assert/strict';
import {execFileSync, spawnSync} from 'node:child_process';
import {copyFileSync, existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, join} from 'node:path';
import test from 'node:test';
import {fileURLToPath} from 'node:url';

const sourceDirectory = dirname(fileURLToPath(import.meta.url));

// Stub only the three yq queries used by the verifier. JSON is valid YAML and
// keeps these orchestration tests independent of installed validators.
const yqStub = `#!/usr/bin/env node
const {readFileSync} = require('node:fs');
const args = process.argv.slice(2);
const query = args.at(-2);
const document = JSON.parse(readFileSync(args.at(-1), 'utf8'));
let value;
if (query.includes('.data.')) {
  const key = query.match(/"([^\"]+)"/)[1];
  value = document.data[key];
} else if (query.includes('.image')) {
  value = document.spec.template.spec.containers.find(c => c.name === 'prow-controller-manager').image;
} else {
  throw new Error('Unexpected yq query: ' + query);
}
if (typeof value !== 'string' || value === '') process.exit(1);
process.stdout.write(value + '\\n');
`;

// This records what the real verifier passes to either executable, including
// staged contents before the verifier's cleanup trap removes its private tree.
const checkerStub = `#!/usr/bin/env node
const {readdirSync, readFileSync, statSync} = require('node:fs');
const {basename, dirname, join} = require('node:path');
const args = process.argv.slice(2);
const option = name => args.find(arg => arg.startsWith(name + '='))?.slice(name.length + 1);
const configPath = option('--config-path');
const pluginPath = option('--plugin-config');
if (!configPath || !pluginPath) throw new Error('Missing Prow configuration paths');
const stagingDirectory = dirname(configPath);
const jobsDirectory = option('--job-config-path');
const jobs = {};
function readJobs(directory, prefix = '') {
  for (const entry of readdirSync(directory, {withFileTypes: true})) {
    const relative = prefix + entry.name;
    if (entry.isDirectory()) readJobs(join(directory, entry.name), relative + '/');
    else jobs[relative] = readFileSync(join(directory, entry.name), 'utf8');
  }
}
if (jobsDirectory) readJobs(jobsDirectory);
const metadata = statSync(stagingDirectory);
console.log(JSON.stringify({executable: basename(process.argv[1]), args,
  stagingDirectory, mode: metadata.mode & 0o777, uid: metadata.uid, gid: metadata.gid,
  config: readFileSync(configPath, 'utf8'), plugins: readFileSync(pluginPath, 'utf8'), jobs}));
process.exit(Number(process.env.TEST_CHECKER_EXIT || 0));
`;

function fixture(t) {
  const cwd = mkdtempSync(join(tmpdir(), 'falco-ci-prow-test-'));
  t.after(() => rmSync(cwd, {recursive: true, force: true}));
  const write = (path, content, mode) => {
    const destination = join(cwd, path);
    mkdirSync(dirname(destination), {recursive: true});
    writeFileSync(destination, content, {mode});
  };
  const env = {
    PATH: `${join(cwd, 'bin')}:${dirname(process.execPath)}:/usr/bin:/bin`,
    TMPDIR: join(cwd, 'temporary'),
    GIT_CONFIG_GLOBAL: '/dev/null', GIT_CONFIG_NOSYSTEM: '1',
    CI: 'false', LC_ALL: 'C',
  };
  mkdirSync(env.TMPDIR);
  mkdirSync(join(cwd, 'tools/ci'), {recursive: true});
  for (const script of ['verify-prow.sh', 'prow-version.sh']) {
    copyFileSync(join(sourceDirectory, script), join(cwd, 'tools/ci', script));
  }
  const [version, image] = execFileSync('bash', ['-c',
    'source tools/ci/prow-version.sh; printf "%s\\n%s\\n" "$prow_version" "$checkconfig_image"'],
  {cwd, env, encoding: 'utf8'}).trim().split('\n');
  assert.match(version, /^v\d{8}-[a-f0-9]+$/);
  assert.match(image, /\/checkconfig:.*@sha256:[a-f0-9]{64}$/);
  const writeRuntime = runtimeVersion => write('config/prow/oci/prow-controller-manager.yaml', JSON.stringify({
    apiVersion: 'apps/v1', kind: 'Deployment', spec: {template: {spec: {containers: [{
      name: 'prow-controller-manager', image: `example.invalid/prow:${runtimeVersion}@sha256:${'0'.repeat(64)}`,
    }]}}},
  }));
  writeRuntime(version);
  write('config/prow/oci/config.yaml', JSON.stringify({data: {'config.yaml': 'prowjob_namespace: prow\npod_namespace: test-pods\n'}}));
  write('config/prow/oci/plugins.yaml', JSON.stringify({data: {'plugins.yaml': 'plugins: {}\n'}}));
  write('bin/yq', yqStub, 0o755);
  write('bin/docker', checkerStub, 0o755);
  write('bin/checkconfig', checkerStub, 0o755);
  const git = (...args) => execFileSync('git', args, {cwd, env, encoding: 'utf8'});
  git('init', '-q');
  return {cwd, write, writeRuntime, git, image,
    run: overrides => spawnSync('bash', ['tools/ci/verify-prow.sh'], {
      cwd, env: {...env, CHECKCONFIG_BIN: join(cwd, 'bin/checkconfig'), ...overrides},
      encoding: 'utf8', timeout: 10000,
    }),
  };
}

function report(result, status = 0) {
  assert.ifError(result.error);
  assert.equal(result.status, status, result.stderr || result.stdout);
  const lines = result.stdout.trim().split('\n').filter(line => line.startsWith('{'));
  assert.equal(lines.length, 1, 'The checker must run exactly once');
  const record = JSON.parse(lines[0]);
  assert.equal(existsSync(record.stagingDirectory), false, 'Private staging must be cleaned up');
  return record;
}

test('Prow configuration is checked without creating an OCI catalog', t => {
  const f = fixture(t);
  const checked = report(f.run());
  assert.equal(checked.executable, 'checkconfig');
  assert.equal(checked.config.trim(), 'prowjob_namespace: prow\npod_namespace: test-pods');
  assert.equal(checked.plugins.trim(), 'plugins: {}');
  assert.deepEqual(checked.jobs, {});
  assert(!checked.args.some(arg => arg.startsWith('--job-config-path=')));
  assert.equal(existsSync(join(f.cwd, 'config/jobs/oci')), false);
  for (const argument of ['--strict', '--warnings=unknown-fields-all', '--warnings=valid-decoration-config']) {
    assert(checked.args.includes(argument), `Missing validation argument: ${argument}`);
  }
});

test('OCI catalog stages tracked and untracked YAML/YML, including nested unusual paths', t => {
  const f = fixture(t);
  const jobs = {
    'tracked.yaml': 'presubmits: {}\n',
    'nested/tracked with spaces.yml': 'postsubmits: {}\n',
    'untracked.yml': 'periodics: []\n',
    'nested/space and\nnewline.yaml': 'presubmits: {}\n',
  };
  for (const [path, content] of Object.entries(jobs)) f.write(`config/jobs/oci/${path}`, content);
  f.git('add', '--', 'config/jobs/oci/tracked.yaml', 'config/jobs/oci/nested/tracked with spaces.yml');
  f.write('.gitignore', 'config/jobs/oci/ignored.yaml\nconfig/jobs/oci/nested/ignored.yml\n');
  f.write('config/jobs/oci/ignored.yaml', 'must not be copied');
  f.write('config/jobs/oci/nested/ignored.yml', 'must not be copied');
  f.write('config/jobs/oci/notes.txt', 'must not be copied');
  f.write('config/jobs/aws/aws.yaml', 'must not be copied');
  assert.deepEqual(report(f.run()).jobs, jobs);
});

test('CI cannot bypass the pinned, hardened Docker checker with CHECKCONFIG_BIN', t => {
  const f = fixture(t);
  const checked = report(f.run({CI: 'true', CHECKCONFIG_BIN: '/does-not-exist'}));
  assert.equal(checked.executable, 'docker');
  for (const argument of ['run', '--rm', '--network=none', '--read-only', '--cap-drop=ALL', '--security-opt=no-new-privileges']) {
    assert(checked.args.includes(argument), `Missing Docker argument: ${argument}`);
  }
  assert(checked.args.includes(f.image), 'Use the exact pinned checkconfig image');
  assert.equal(checked.args[checked.args.indexOf('--user') + 1], `${process.getuid()}:${process.getgid()}`);
  assert.equal(checked.mode, 0o700, 'Staged configuration must remain private');
  assert.equal(checked.uid, process.getuid());
  assert.equal(checked.gid, process.getgid());
  assert.equal(checked.args[checked.args.indexOf('--mount') + 1],
    `type=bind,src=${checked.stagingDirectory},dst=${checked.stagingDirectory},readonly`);
  assert.equal(checked.args.filter(arg => arg === '--mount').length, 1);
});

for (const ci of ['false', 'true']) {
  test(`Checker failure propagates and staging is cleaned up (CI=${ci})`, t => {
    const f = fixture(t);
    report(f.run({CI: ci, TEST_CHECKER_EXIT: '23'}), 23);
  });
}

test('Mismatched Prow runtime version fails before either checker runs', t => {
  const f = fixture(t);
  f.writeRuntime('v20000101-000000000');
  const result = f.run();
  assert.ifError(result.error);
  assert.notEqual(result.status, 0);
  assert(!result.stdout.split('\n').some(line => line.startsWith('{')));
});
