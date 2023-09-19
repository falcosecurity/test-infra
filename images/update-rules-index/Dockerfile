FROM golang:1.21 AS pullrequestcreator

RUN git clone https://github.com/kubernetes/test-infra
RUN cd test-infra/robots/pr-creator && env GO111MODULE=on go build -v -o pr-creator ./main.go

FROM golang:1.21

LABEL usage="docker run -i -t -v /path/to/source:/workspace test-infra/update-rules-index"

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /bin

COPY on-registry-changed.sh /
RUN chmod +x /on-registry-changed.sh

WORKDIR /workspace
