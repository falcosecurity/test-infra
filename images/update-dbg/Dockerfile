FROM golang:1.21 AS pullrequestcreator

RUN git clone https://github.com/kubernetes/test-infra
RUN cd test-infra/robots/pr-creator && go build -v -o pr-creator ./main.go

FROM golang:1.21-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    gnupg2 \
    curl \
    wget \
    && apt-get clean

RUN wget -q https://github.com/falcosecurity/dbg-go/releases/download/v0.13.0/dbg-go_0.13.0_linux_amd64.tar.gz \
    && tar -xvf dbg-go_0.13.0_linux_amd64.tar.gz \
    && chmod +x dbg-go \
    && mv dbg-go /bin/dbg-go

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /bin
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
