# Falco dashboard branding

These unmodified assets come from the official Falco website at commit
[`e3a52667122dd3aacd6690441717601136caaa12`](https://github.com/falcosecurity/falco-website/tree/e3a52667122dd3aacd6690441717601136caaa12).

- [logo.png](logo.png): white Falco symbol and wordmark for the teal navbar.
  [Original asset](https://github.com/falcosecurity/falco-website/blob/e3a52667122dd3aacd6690441717601136caaa12/static/img/brand/falco-horizontal-white.png).
- [favicon.png](favicon.png): 32×32 teal Falco symbol without the wordmark.
  [Original asset](https://github.com/falcosecurity/falco-website/blob/e3a52667122dd3aacd6690441717601136caaa12/static/favicons/favicon-32x32.png).

The [Kustomization](../kustomization.yaml) generates a content-hashed ConfigMap
mounted read-only by [Deck](../deck.yaml). [Prow configuration](../config.yaml)
uses a URL for the navbar logo and a path relative to Deck's static directory
for the favicon. [Regression tests](../../../../tools/ci/verify-branding.test.mjs)
check both assets and the rendered mount.

[style.css](style.css) sizes the navbar logo to 32px while preserving its aspect
ratio. Deck mounts only this CSS extension file with `subPath`, leaving the
upstream extension directory and JavaScript intact. The stylesheet shares the
content-hashed ConfigMap, so changing it updates the Deployment's volume reference.
