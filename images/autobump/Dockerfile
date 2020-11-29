FROM golang:1.13 AS build

COPY pr-creator/ /pr-creator

RUN cd /pr-creator/ && \
    env CGO_ENABLED=0 \
        GO111MODULE=on \
        GOPROXY=https://proxy.golang.org \
        GOSUMDB=sum.golang.org \
        go build -v -o pr-creator ./main.go

FROM gcr.io/k8s-testimages/gcloud-in-go:v20200205-602500d

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg2 \
    rng-tools 

COPY --from=build /pr-creator/pr-creator /pr-creator

COPY bump.sh /bump.sh

COPY autobump.sh /autobump.sh

RUN chmod 755 /bump.sh

RUN chmod 755 /autobump.sh

ENTRYPOINT ["/autobump.sh"]