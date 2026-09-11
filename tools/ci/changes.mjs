// SPDX-License-Identifier: Apache-2.0
import {execFileSync} from 'node:child_process';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';

export function selectClouds(paths) {
  const selected = {aws: false, oci: false};
  for (const path of paths) {
    // Bootstrap is deliberately local-only, including changes to its scripts.
    if (path.startsWith('config/clusters/oci/bootstrap/')) continue;
    if (path.endsWith('.md') || path === 'OWNERS' || path.endsWith('/OWNERS')) continue;
    const cloud = path.match(/^config\/(?:applications|clusters|jobs|prow)\/(aws|oci)\//);
    if (cloud) {
      selected[cloud[1]] = true;
    } else if (path === '.github/workflows/ci-oci.yml' || path === 'tools/deploy_argocd_oci.sh'
      || ['tools/ci/prow-version.sh', 'tools/ci/verify-prow.sh', 'tools/ci/verify-prow.test.mjs',
        'tools/ci/verify-branding.test.mjs'].includes(path)) {
      selected.oci = true;
    } else if (/^\.github\/workflows\/(?:ci-aws|job-checker|job-checker-builder|prow|argocd|terraform-plan|terraform-apply)\.yml$/.test(path)
      || path.startsWith('tools/prow-jobs-checker/') || path.startsWith('prow/')
      || path === 'config/org.yaml'
      || /^tools\/(?:deploy_prow|deploy_argocd|local_prowjob|delete_local_prowjob|clean_prowjobs|util)\.sh$/.test(path)) {
      selected.aws = true;
    } else if (path === '.github/workflows/ci.yml' || path.startsWith('tools/ci/')
      || path.startsWith('.github/actions/') || path === 'Makefile' || path === '.gitignore'
      || path === 'tools/terraform.Makefile'
      || /^config\/(?:applications|clusters|jobs|prow)\//.test(path)) {
      selected.aws = selected.oci = true;
    }
  }
  return selected;
}

export function changedPaths(base, head, cwd = process.cwd()) {
  const git = (...args) => execFileSync('git', args, {cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 64 * 1024 * 1024});
  const commit = ref => git('rev-parse', '--verify', '--end-of-options', `${ref}^{commit}`).trim();
  // Treat renames as deletion + addition so both cloud paths are considered.
  return git('diff', '--no-ext-diff', '--no-textconv', '--no-renames', '--name-only', '-z',
    commit(base), commit(head), '--').split('\0').filter(Boolean);
}

export function pullRequestPaths(cwd = process.cwd()) {
  const parents = execFileSync('git', ['rev-list', '--parents', '-n', '1', 'HEAD'],
    {cwd, encoding: 'utf8'}).trim().split(/\s+/);
  if (parents.length !== 3) throw new Error('Expected the pull_request merge commit and both parents (checkout fetch-depth: 2).');
  // Compare the tested merge result with its base parent, not with a stale PR base.
  return changedPaths(parents[1], parents[0], cwd);
}

export function validateResults(needs) {
  if (needs.changes?.result !== 'success') throw new Error('Cloud selection failed or was cancelled.');
  for (const cloud of ['aws', 'oci']) {
    const selected = needs.changes.outputs?.[cloud];
    if (!['true', 'false'].includes(selected)) throw new Error(`Missing selection for ${cloud}.`);
    const expected = selected === 'true' ? 'success' : 'skipped';
    if (needs[cloud]?.result !== expected) throw new Error(`${cloud}: expected ${expected}, got ${needs[cloud]?.result}.`);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    const args = process.argv.slice(2);
    if (args.length === 1 && args[0] === '--gate') {
      validateResults(JSON.parse(process.env.CI_RESULTS));
      console.log('All selected cloud checks passed.');
    } else {
      let paths;
      if (args.length === 1 && args[0] === '--pull-request') paths = pullRequestPaths();
      else if (args.length === 2) paths = changedPaths(...args);
      else throw new Error('Usage: node tools/ci/changes.mjs --pull-request | BASE HEAD | --gate');
      for (const [cloud, selected] of Object.entries(selectClouds(paths))) console.log(`${cloud}=${selected}`);
    }
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
