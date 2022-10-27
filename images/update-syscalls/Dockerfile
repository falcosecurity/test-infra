FROM golang:1.18 AS pullrequestcreator

RUN git clone https://github.com/kubernetes/test-infra
RUN cd test-infra/robots/pr-creator && go build -v -o pr-creator ./main.go

FROM debian:buster

ADD https://github.com/FedeDP/syscalls-bumper/releases/download/v0.0.3/syscalls-bumper_0.0.3_linux_amd64.tar.gz .
RUN tar -xvf syscalls-bumper_0.0.3_linux_amd64.tar.gz \
    && chmod +x syscalls-bumper \
    && mv syscalls-bumper /bin/syscalls-bumper

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /bin

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
