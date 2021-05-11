FROM 292999226676.dkr.ecr.eu-west-1.amazonaws.com/test-infra/docker-dind

ENV PUBLISH_S3="false"

RUN wget -q https://github.com/falcosecurity/driverkit/releases/download/v0.4.0/driverkit_0.4.0_linux_amd64.tar.gz \
    && tar -xvf driverkit_0.4.0_linux_amd64.tar.gz \
    && chmod +x driverkit \
    && mv driverkit /bin/driverkit

COPY build-drivers.sh /workspace/build-drivers.sh

RUN chmod 755 /workspace/build-drivers.sh

ENV DOCKER_API_VERSION=1.38

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
