FROM golang:1.26.7-bookworm@sha256:e8c859f5632dcfde7b32d2012b4351728f6437930887c2f6a91ea242459e5514 AS pullrequestcreator

ARG PR_CREATOR_REF=f1d922fc202a10825bbc599605a4bedce2fbf048
RUN git init test-infra \
    && cd test-infra \
    && git remote add origin https://github.com/kubernetes/test-infra \
    && git fetch --depth=1 origin "$PR_CREATOR_REF" \
    && git checkout --detach FETCH_HEAD
RUN cd test-infra/robots/pr-creator && CGO_ENABLED=0 go build -p 2 -mod=readonly -v -o pr-creator ./main.go

FROM golang:1.26.7-bookworm@sha256:e8c859f5632dcfde7b32d2012b4351728f6437930887c2f6a91ea242459e5514

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    gnupg2 \
    curl \
    && apt-get clean

ARG TARGETARCH
RUN arch="${TARGETARCH:-$(dpkg --print-architecture)}" \
    && case "$arch" in \
      amd64) sha256=1e4ab49e429626cf6c6958d914248b78c9730803c2751b87627e171dc800e7bb ;; \
      arm64) sha256=f14e804dfee240f55525b667488fe9adca349e63e00c9af634c0beb1421ac310 ;; \
      *) echo "unsupported architecture: $arch" >&2; exit 1 ;; esac \
    && curl -fsSL -o /tmp/helm.tar.gz "https://get.helm.sh/helm-v3.22.0-linux-${arch}.tar.gz" \
    && echo "$sha256  /tmp/helm.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/helm.tar.gz -C /usr/local/bin --strip-components=1 "linux-${arch}/helm" \
    && rm /tmp/helm.tar.gz
RUN arch="${TARGETARCH:-$(dpkg --print-architecture)}" \
    && case "$arch" in \
      amd64) sha256=029a7f0f4e1932c52a0476cf02a0fd855c0bb85694b82c338fc648dcb53a819d ;; \
      arm64) sha256=0953ea3e476f66d6ddfcd911d750f5167b9365aa9491b2326398e289fef2c142 ;; \
      *) echo "unsupported architecture: $arch" >&2; exit 1 ;; esac \
    && curl -fsSL -o /tmp/kustomize.tar.gz "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v5.8.1/kustomize_v5.8.1_linux_${arch}.tar.gz" \
    && echo "$sha256  /tmp/kustomize.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/kustomize.tar.gz -C /usr/local/bin kustomize \
    && rm /tmp/kustomize.tar.gz

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /bin
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
