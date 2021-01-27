FROM golang:1.15 AS hook

# COPY hook /go/github.com/falcosecurity/hook/
ENV GOPROXY=direct
RUN cd /go/github.com/falcosecurity/hook/ && go build -v -o hook

FROM debian:buster

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    gnupg2 \
    curl \
    && apt-get clean

COPY --from=hook /go/github.com/falcosecurity/hook/hook /bin
ENTRYPOINT ["sleep"]
