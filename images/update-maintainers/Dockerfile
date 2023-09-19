FROM golang:1.21 AS pullrequestcreator

RUN git clone https://github.com/kubernetes/test-infra
RUN cd test-infra/robots/pr-creator && env GO111MODULE=on go build -v -o pr-creator ./main.go

FROM golang:1.21 AS maintainersgenerator

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
