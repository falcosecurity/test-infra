FROM golang:1.18 AS pullrequestcreator

RUN git clone https://github.com/kubernetes/test-infra
RUN cd test-infra/robots/pr-creator && go build -v -o pr-creator ./main.go

FROM golang:1.19 AS builder

RUN git clone https://github.com/FedeDP/syscalls-bumper.git
RUN cd syscalls-bumper && make build

FROM debian:buster

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /bin
COPY --from=builder /go/syscalls-bumper/build/syscalls-bumper /bin

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
