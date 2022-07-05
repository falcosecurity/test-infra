FROM debian:buster

ARG COSIGN_VERSION=1.9.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    jq \
    dnsutils \
    openssh-client \
    python \
    wget \
    apt-transport-https \
    gnupg2 \
    shellcheck \
    software-properties-common \
    lsb-release \
    gettext \
    groff \
    unzip \
    && apt-get clean
    
# Docker-in-docker
RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg \
    | apt-key add - && \
    add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
    $(lsb_release -cs) stable"

ENV DOCKER_VERSION=5:20.10.1*

RUN apt-get update && \
    apt-get install -y --no-install-recommends docker-ce=${DOCKER_VERSION} && \
    sed -i 's/cgroupfs_mount$/#cgroupfs_mount\n/' /etc/init.d/docker

RUN echo 'DOCKER_OPTS="${DOCKER_OPTS} --data-root=/docker-graph"' | \
    tee --append /etc/default/docker
RUN mkdir /docker-graph

RUN tmpdir=`mktemp -d` && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "${tmpdir}/awscliv2.zip" && \
	unzip $tmpdir/awscliv2.zip -d $tmpdir && \
	$tmpdir/aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
	rm -r $tmpdir

RUN apt-get update && TMPDIR=$(mktemp -d) \
	&& curl -SL -o $TMPDIR/cosign.deb \
		"https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign_${COSIGN_VERSION}_amd64.deb" \
	&& apt-get install -y --no-install-recommends \
		$TMPDIR/cosign.deb \
	&& apt-get clean
