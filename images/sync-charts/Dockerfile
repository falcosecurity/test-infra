FROM golang:1.24 AS pullrequestcreator

RUN mkdir -p /go/test-infra/robots/pr-creator
COPY --from=gcr.io/k8s-prow/pr-creator@sha256:776cc7d7aa8e7dc0a557c53aa83d3edd7cceafc3119e889a81c0655851783518 /ko-app/pr-creator /go/test-infra/robots/pr-creator/pr-creator

FROM golang:1.24-bookworm

ARG HELM_VERSION=v4.1.1
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    gnupg2 \
    curl \
    rsync \
    && apt-get clean

RUN helm_arch="${TARGETARCH:-$(dpkg --print-architecture)}" \
    && case "${helm_arch}" in amd64|arm64) ;; *) echo "unsupported architecture: ${helm_arch}" >&2; exit 1 ;; esac \
    && curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${helm_arch}.tar.gz" \
    | tar -xz -C /tmp \
    && mv "/tmp/linux-${helm_arch}/helm" /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf "/tmp/linux-${helm_arch}"

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /bin
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
