FROM golang:1.18 AS pullrequestcreator

RUN git clone https://github.com/kubernetes/test-infra
RUN cd test-infra/robots/pr-creator && go build -v -o pr-creator ./main.go

FROM gcr.io/k8s-testimages/gcloud-in-go:v20200205-602500d

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg2 \
    rng-tools

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /pr-creator

COPY bump.sh /bump.sh

COPY autobump.sh /autobump.sh

RUN chmod 755 /bump.sh

RUN chmod 755 /autobump.sh

ENTRYPOINT ["/autobump.sh"]
