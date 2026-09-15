FROM golang:1.26.7-bookworm@sha256:e8c859f5632dcfde7b32d2012b4351728f6437930887c2f6a91ea242459e5514 AS pullrequestcreator

ARG PR_CREATOR_REF=f1d922fc202a10825bbc599605a4bedce2fbf048
RUN git init test-infra \
    && cd test-infra \
    && git remote add origin https://github.com/kubernetes/test-infra \
    && git fetch --depth=1 origin "$PR_CREATOR_REF" \
    && git checkout --detach FETCH_HEAD
RUN cd test-infra/robots/pr-creator && CGO_ENABLED=0 go build -mod=readonly -v -o pr-creator ./main.go

FROM golang:1.24 AS maintainersgenerator

RUN wget -qO- "https://api.github.com/repos/leodido/maintainers-generator/releases/latest" | grep -Po '"browser_download_url": "\K.*?(?=")' | xargs wget -qO- | tar -xvz

FROM golang:1.21-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    gnupg2 \
    curl \
    && apt-get clean

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /bin
COPY --from=maintainersgenerator /go/maintainers-generator /bin
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
