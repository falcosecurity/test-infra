FROM golang:1.18 AS pigeon

RUN curl -s "https://api.github.com/repos/falcosecurity/pigeon/releases/latest" | grep "browser_download_url.*tar.gz" \
| cut -d : -f 2,3 \
| tr -d \" \
| xargs wget -qO- \
| tar -xvz

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y libsodium-dev

COPY --from=pigeon /go/pigeon /bin