FROM golang:1.20 AS gobuilder

RUN git clone https://github.com/kubernetes/test-infra
RUN cd test-infra/robots/pr-creator && go build -v -o pr-creator ./main.go

ADD dbg-go dbg-go
RUN cd dbg-go && go build .

FROM debian:buster

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    gnupg2 \
    curl \
    make \
    jq \
    && apt-get clean

COPY --from=gobuilder /go/test-infra/robots/pr-creator/pr-creator /bin
COPY --from=gobuilder /go/dbg-go/dbg-go /bin

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
