FROM golang:1.18 AS pullrequestcreator

RUN git clone https://github.com/kubernetes/test-infra
RUN cd test-infra/robots/pr-creator && env GO111MODULE=on go build -v -o pr-creator ./main.go

FROM golang:1.18

LABEL usage="docker run -i -t -v /path/to/source:/workspace test-infra/build-plugins"

ENV PUBLISH_S3="true"
ENV PUBLISH_TAG="dev"
ENV S3_PATH="s3://falco-distribution/plugins/"

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    && apt-get clean

RUN pip install awscli

COPY --from=pullrequestcreator /go/test-infra/robots/pr-creator/pr-creator /bin

COPY build-and-publish.sh /
RUN chmod +x /build-and-publish.sh

COPY update-readme.sh /
RUN chmod +x /update-readme.sh

COPY build.sh /
RUN chmod +x /build.sh

WORKDIR /workspace

ENTRYPOINT ["/build-and-publish.sh"]
