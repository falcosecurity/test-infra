# --- Args --- 

ARG GOVERSION=1.15.7-alpine
ARG GOPATH=/go
ARG APP_NAME=update-jobs

# --- Build ---

FROM golang:$GOVERSION as builder

ARG GOPATH
ARG APP_NAME

RUN apk --no-cache add \
	make \
	bash

WORKDIR ${GOPATH}/src/${APP_NAME}

COPY . .

RUN OUTPUT_BASE=${GOPATH} make build

# --- Final ---

FROM golang:$GOVERSION as final

ARG GOPATH
ARG APP_NAME
ENV GOPATH=$GOPATH

COPY ./scripts/entrypoint.sh /
COPY --from=builder ${GOPATH}/bin/${APP_NAME} ${GOPATH}/bin/${APP_NAME}

ENTRYPOINT ["/entrypoint.sh"]
CMD ["${GOPATH}/bin/${APP_NAME}"]
