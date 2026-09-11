// SPDX-License-Identifier: Apache-2.0
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const repo = fileURLToPath(new URL('../../', import.meta.url));
const brandingPath = `${repo}config/prow/oci/branding/`;
const render = execFileSync('kustomize', ['build', `${repo}config/prow/oci`], {
  encoding: 'utf8', maxBuffer: 10 * 1024 * 1024,
});
const resources = execFileSync('yq', ['-o=json', '-I=0', '.'], {
  input: render, encoding: 'utf8', maxBuffer: 10 * 1024 * 1024,
}).trim().split('\n').map((line) => JSON.parse(line));
const yaml = (content) => JSON.parse(execFileSync('yq', ['-o=json', '.', '-'], {
  input: content, encoding: 'utf8',
}));
const sha256 = (content) => createHash('sha256').update(content).digest('hex');
const deck = resources.find((resource) => resource.kind === 'Deployment' && resource.metadata.name === 'deck');
const config = resources.find((resource) => resource.kind === 'ConfigMap' && resource.metadata.name === 'config');
const branding = yaml(config.data['config.yaml']).deck.branding;
const volume = deck.spec.template.spec.volumes.find((item) => item.name === 'branding');
const assets = resources.find((resource) => resource.kind === 'ConfigMap' && resource.metadata.name === volume.configMap.name);

// Official assets at falcosecurity/falco-website@e3a52667122dd3aacd6690441717601136caaa12:
// static/img/brand/falco-horizontal-white.png and static/favicons/favicon-32x32.png.
const expectedAssets = {
  'logo.png': { width: 277, height: 100, sha: 'f670fbd5d0876f723ec43cf0f4c05d797c67117c57938a602be74f765f2388eb' },
  'favicon.png': { width: 32, height: 32, sha: '035a4b86bf739550573a08d63564961cf04ebbc9bd7a1b896ffcfbb81653292c' },
};

test('Deck uses the full white Falco logo and an independent icon-only favicon', () => {
  assert.equal(branding.header_color, '#00AEC7');
  assert.equal(branding.logo, '/static/branding/logo.png');
  // Deck resolves favicon relative to its static directory, not as a URL.
  assert.equal(branding.favicon, 'branding/favicon.png');
});

test('branding assets retain the verified official bytes and dimensions', () => {
  for (const [name, expected] of Object.entries(expectedAssets)) {
    const content = readFileSync(`${brandingPath}${name}`);
    assert.equal(content.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
    assert.equal(content.readUInt32BE(16), expected.width, `${name}: width`);
    assert.equal(content.readUInt32BE(20), expected.height, `${name}: height`);
    assert.equal(sha256(content), expected.sha, `${name}: official asset`);
    assert.equal(sha256(Buffer.from(assets.binaryData[name], 'base64')), expected.sha, `${name}: rendered asset`);
  }
});

test('Kustomize binds Deck to the namespaced, content-hashed branding ConfigMap', () => {
  assert.equal(assets.metadata.namespace, 'prow');
  assert.match(assets.metadata.name, /^branding-[a-z0-9]{10}$/);
  assert.equal(assets.metadata.labels['app.kubernetes.io/name'], 'deck');
  assert.equal(assets.metadata.labels['app.kubernetes.io/component'], 'dashboard');
  assert.equal(assets.metadata.labels['app.kubernetes.io/part-of'], 'prow');
  assert.deepEqual(Object.keys(assets.binaryData).sort(), ['favicon.png', 'logo.png']);
});

test('Deck mounts branding read-only without hiding the upstream extension directory', () => {
  const container = deck.spec.template.spec.containers.find((item) => item.name === 'deck');
  const mount = container.volumeMounts.find((item) => item.name === 'branding');
  assert.equal(mount.mountPath, '/var/run/ko/static/branding');
  assert.equal(mount.readOnly, true);
  assert.equal(volume.configMap.defaultMode, 0o444);
  assert.equal(container.securityContext.readOnlyRootFilesystem, true);
  assert.ok(container.volumeMounts.every((item) => !['/var/run/ko/static', '/var/run/ko/static/extensions'].includes(item.mountPath)));
});

test('Deck loads the scoped 32px navbar sizing through its CSS extension', () => {
  const css = readFileSync(`${brandingPath}style.css`, 'utf8');
  assert.deepEqual(Object.keys(assets.data), ['style.css']);
  assert.equal(assets.data['style.css'], css);
  assert.match(css, /#header-title \.logo\s*\{\s*height:\s*32px;\s*\}/);
  assert.match(css, /#header-title img\.logo\s*\{\s*width:\s*auto;\s*\}/);

  const container = deck.spec.template.spec.containers.find((item) => item.name === 'deck');
  const mount = container.volumeMounts.find((item) => item.mountPath === '/var/run/ko/static/extensions/style.css');
  assert.equal(mount.name, 'branding');
  assert.equal(mount.subPath, 'style.css');
  assert.equal(mount.readOnly, true);
  assert.ok(container.volumeMounts.every((item) => item.mountPath !== '/var/run/ko/static/extensions/script.js'));
});
