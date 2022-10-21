FROM golang:1.18

ADD updateDriversWebsite.go .
RUN go build -v -o /bin/update-drivers-website ./updateDriversWebsite.go

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    awscli \
    && apt-get clean

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
