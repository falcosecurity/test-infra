FROM golang:1.17

LABEL usage="docker run -i -t -v /path/to/source:/workspace test-infra/build-plugins"

ENV PUBLISH_S3="true"
ENV PUBLISH_TAG="dev"
ENV S3_PATH="s3://falco-distribution/plugins/"

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    && apt-get clean

RUN pip install awscli

COPY build-and-publish.sh /
RUN chmod +x /build-and-publish.sh

WORKDIR /workspace

ENTRYPOINT ["/build-and-publish.sh"]
