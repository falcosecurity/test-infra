FROM golang:1.26.7-bookworm@sha256:e8c859f5632dcfde7b32d2012b4351728f6437930887c2f6a91ea242459e5514 AS pullrequestcreator

RUN mkdir -p /go/test-infra/robots/pr-creator
COPY --from=gcr.io/k8s-prow/pr-creator@sha256:776cc7d7aa8e7dc0a557c53aa83d3edd7cceafc3119e889a81c0655851783518 /ko-app/pr-creator /go/test-infra/robots/pr-creator/pr-creator

FROM golang:1.26.7-bookworm@sha256:e8c859f5632dcfde7b32d2012b4351728f6437930887c2f6a91ea242459e5514

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
    && case "${helm_arch}" in \
      amd64) helm_sha256=5d4c7623283e6dfb1971957f4b755468ab64917066a8567dd50464af298f4031 ;; \
      arm64) helm_sha256=02a5fb7742469d2d132e24cb7c3f52885894043576588c6788b6813297629edd ;; \
      *) echo "unsupported architecture: ${helm_arch}" >&2; exit 1 ;; esac \
    && curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${helm_arch}.tar.gz" \
      -o /tmp/helm.tar.gz \
    && echo "${helm_sha256}  /tmp/helm.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/helm.tar.gz -C /tmp \
    && mv "/tmp/linux-${helm_arch}/helm" /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf "/tmp/linux-${helm_arch}" /tmp/helm.tar.gz

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /bin
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
