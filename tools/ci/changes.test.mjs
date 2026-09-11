// SPDX-License-Identifier: Apache-2.0
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {mkdtempSync, mkdirSync, writeFileSync, rmSync, renameSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, join} from 'node:path';
import test from 'node:test';
import {changedPaths, pullRequestPaths, selectClouds, validateResults} from './changes.mjs';

const aws = {aws: true, oci: false};
const oci = {aws: false, oci: true};
const both = {aws: true, oci: true};
const neither = {aws: false, oci: false};
for (const [name, paths, expected] of [
  ['AWS manifests', ['config/prow/aws/manifests/deck.yaml'], aws],
  ['OCI manifests', ['config/prow/oci/deck.yaml'], oci],
  ['Future OCI job catalog', ['config/jobs/oci/example/job.yaml'], oci],
  ['AWS applications', ['config/applications/aws/falco.yaml'], aws],
  ['OCI applications', ['config/applications/oci/gateway/httproute-prow.yaml'], oci],
  ['AWS Terraform', ['config/clusters/aws/eks.tf'], aws],
  ['OCI Terraform', ['config/clusters/oci/.terraform.lock.hcl'], oci],
  ['OCI Terraform version', ['config/clusters/oci/.terraform-version'], oci],
  ['OCI bootstrap', ['config/clusters/oci/bootstrap/main.tf', 'config/clusters/oci/bootstrap/run.sh'], neither],
  ['Bootstrap and AWS', ['config/clusters/oci/bootstrap/main.tf', 'config/prow/aws/config.yaml'], aws],
  ['Both clouds', ['config/jobs/aws/test.yaml', 'config/prow/oci/config.yaml'], both],
  ['Shared CI', ['tools/ci/changes.mjs'], both],
  ['Shared workflow', ['.github/workflows/ci.yml'], both],
  ['AWS workflow', ['.github/workflows/ci-aws.yml'], aws],
  ['OCI workflow', ['.github/workflows/ci-oci.yml'], oci],
  ['OCI Prow checker', ['tools/ci/verify-prow.sh'], oci],
  ['OCI Prow checker tests', ['tools/ci/verify-prow.test.mjs'], oci],
  ['OCI Prow version pins', ['tools/ci/prow-version.sh'], oci],
  ['AWS checker source', ['tools/prow-jobs-checker/go.mod'], aws],
  ['OCI deployment script', ['tools/deploy_argocd_oci.sh'], oci],
  ['AWS deployment script', ['tools/deploy_argocd.sh'], aws],
  ['Shared Terraform tooling', ['tools/terraform.Makefile'], both],
  ['Unknown infrastructure layout selects both', ['config/prow/shared/config.yaml'], both],
  ['Documentation only', ['README.md', 'config/clusters/oci/README.md'], neither],
  ['Ownership only', ['OWNERS', 'config/jobs/aws/OWNERS'], neither],
  ['Driver catalog has its own checks', ['driverkit/config/10.2.0+driver/x86_64/debian.yaml'], neither],
  ['Empty diff', [], neither],
  ['More than 300 files', [...Array.from({length: 1000}, (_, i) => `driverkit/${i}.yaml`), 'config/prow/oci/config.yaml'], oci],
]) {
  test(name, () => assert.deepEqual(selectClouds(paths), expected));
}

test('Git diff covers deletions, cross-cloud renames and unusual filenames', t => {
  const cwd = mkdtempSync(join(tmpdir(), 'falco-ci-diff-'));
  t.after(() => rmSync(cwd, {recursive: true, force: true}));
  const git = (...args) => execFileSync('git', args, {cwd, encoding: 'utf8', env: {...process.env,
    GIT_CONFIG_GLOBAL: '/dev/null', GIT_CONFIG_NOSYSTEM: '1',
    GIT_AUTHOR_NAME: 'Test', GIT_AUTHOR_EMAIL: 'test@example.invalid',
    GIT_COMMITTER_NAME: 'Test', GIT_COMMITTER_EMAIL: 'test@example.invalid'}}).trim();
  const write = (path, content) => { mkdirSync(dirname(join(cwd, path)), {recursive: true}); writeFileSync(join(cwd, path), content); };
  git('init', '-q', '-b', 'master');
  write('config/prow/aws/renamed.yaml', 'original\n');
  write('config/prow/aws/deleted.yaml', 'deleted\n');
  git('add', '.'); git('commit', '-qm', 'base');
  const base = git('rev-parse', 'HEAD');
  git('switch', '-qc', 'feature');
  mkdirSync(join(cwd, 'config/prow/oci'), {recursive: true});
  renameSync(join(cwd, 'config/prow/aws/renamed.yaml'), join(cwd, 'config/prow/oci/renamed.yaml'));
  rmSync(join(cwd, 'config/prow/aws/deleted.yaml'));
  write('config/prow/oci/spaces and\nnewline.yaml', 'new\n');
  git('add', '.'); git('commit', '-qm', 'feature');
  const paths = changedPaths(base, 'HEAD', cwd);
  assert(paths.includes('config/prow/aws/renamed.yaml'));
  assert(paths.includes('config/prow/aws/deleted.yaml'));
  assert(paths.includes('config/prow/oci/renamed.yaml'));
  assert(paths.includes('config/prow/oci/spaces and\nnewline.yaml'));
  assert.deepEqual(selectClouds(paths), both);
  assert.throws(() => changedPaths('missing-ref', 'HEAD', cwd));
  assert.throws(() => pullRequestPaths(cwd));
  git('switch', '-q', 'master');
  write('config/clusters/aws/upstream.tf', 'upstream change\n');
  git('add', '.'); git('commit', '-qm', 'upstream');
  git('merge', '--no-ff', '-qm', 'test merge', 'feature');
  assert.deepEqual(pullRequestPaths(cwd).sort(), paths.sort());
  git('clone', '-q', '--depth=2', `file://${cwd}`, 'shallow');
  assert.deepEqual(pullRequestPaths(join(cwd, 'shallow')).sort(), paths.sort());
});

test('Required gate accepts only successful selected checks', () => {
  for (const selected of [aws, oci, both, neither]) {
    const needs = {changes: {result: 'success', outputs: {
      aws: String(selected.aws), oci: String(selected.oci)}},
      aws: {result: selected.aws ? 'success' : 'skipped'},
      oci: {result: selected.oci ? 'success' : 'skipped'}};
    assert.doesNotThrow(() => validateResults(needs));
    for (const cloud of ['aws', 'oci']) {
      for (const result of ['failure', 'cancelled', ...(selected[cloud] ? ['skipped'] : ['success'])]) {
        assert.throws(() => validateResults({...needs, [cloud]: {result}}));
      }
    }
    assert.throws(() => validateResults({...needs, changes: {...needs.changes, result: 'failure'}}));
    assert.throws(() => validateResults({...needs, changes: {result: 'success', outputs: {}}}));
  }
});
