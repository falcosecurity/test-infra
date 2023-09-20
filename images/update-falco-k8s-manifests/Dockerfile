FROM golang:1.21 AS pullrequestcreator

RUN git clone https://github.com/kubernetes/test-infra
RUN cd test-infra/robots/pr-creator && go build -v -o pr-creator ./main.go

FROM golang:1.21-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    gnupg2 \
    curl \
    && apt-get clean

RUN curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
RUN curl -s https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | bash -s /usr/local/bin

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /bin
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
