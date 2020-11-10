FROM golang:1.13

ENV DEP_RELEASE_TAG v0.5.4

ENV GOPATH /workspace
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p ${GOPATH}/bin
RUN mkdir -p ${GOPATH}/src
RUN go get -u github.com/golang/dep/cmd/dep

# Install Dep

RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

WORKDIR /workspace