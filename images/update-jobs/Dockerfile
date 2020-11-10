FROM 292999226676.dkr.ecr.eu-west-1.amazonaws.com/test-infra/golang:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    python \
    curl \
    git \
    groff \
    unzip 

RUN curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip -qq awscliv2.zip \
    && ./aws/install \
    && rm awscliv2.zip \
    && rm -R aws

RUN curl -s "https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.8/2020-09-18/bin/darwin/amd64/aws-iam-authenticator" -o aws-iam-authenticator \
    && chmod +x ./aws-iam-authenticator \
    && mv ./aws-iam-authenticator /bin/aws-iam-authenticator

COPY update-jobs.sh /workspace/update-jobs.sh

RUN chmod 755 /workspace/update-jobs.sh

ENTRYPOINT ["/bin/bash"]