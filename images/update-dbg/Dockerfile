FROM golang:1.26.7-bookworm@sha256:e8c859f5632dcfde7b32d2012b4351728f6437930887c2f6a91ea242459e5514 AS pullrequestcreator

RUN git clone --filter=blob:none --no-checkout https://github.com/kubernetes/test-infra /src \
    && git -C /src checkout 69fb47436fbc509bf03faa6aab2152eca0492a8b
WORKDIR /src
RUN CGO_ENABLED=0 go build -trimpath -o /pr-creator ./robots/pr-creator

FROM ghcr.io/falcosecurity/dbg-go:0.18.0@sha256:e3ae931c8d08c6682111d1b0f3230aee74a49098da809d9981ec72e9a24f9a68 AS dbg

FROM debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    gnupg2 \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=pullrequestcreator /pr-creator /usr/local/bin/pr-creator
COPY --from=dbg /ko-app/dbg-go /usr/local/bin/dbg-go
COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
