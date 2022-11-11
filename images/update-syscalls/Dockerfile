FROM golang:1.18 AS pullrequestcreator

RUN git clone https://github.com/kubernetes/test-infra
RUN cd test-infra/robots/pr-creator && go build -v -o pr-creator ./main.go

FROM debian:buster

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    gnupg2 \
    curl \
    && apt-get clean

ADD https://github.com/falcosecurity/syscalls-bumper/releases/download/v0.0.5/syscalls-bumper_0.0.5_linux_amd64.tar.gz .
RUN tar -xvf syscalls-bumper_0.0.5_linux_amd64.tar.gz \
    && chmod +x syscalls-bumper \
    && mv syscalls-bumper /bin/syscalls-bumper

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /bin

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
