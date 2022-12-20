IMG_NAME = test-infra/docker-dind
ACCOUNT=292999226676
DOCKER_PUSH_REPOSITORY=dkr.ecr.eu-west-1.amazonaws.com
TAG?=latest
IMAGE=$(ACCOUNT).$(DOCKER_PUSH_REPOSITORY)/$(IMG_NAME)

ARCHS := "arm64,amd64"

build-push: push-image

create-builder:
	# Workaround for buildx issue, see https://github.com/docker/buildx/issues/495#issuecomment-761562905
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name dindbuilder --driver docker-container --use
	docker buildx inspect --bootstrap

build-image: create-builder
	docker buildx build --platform $(ARCHS) -o type=image,push="false" .

push-image: create-builder
	docker buildx build --push --platform $(ARCHS) -t "$(IMAGE)" .

local-registry: create-builder
	docker buildx build --push --platform $(ARCHS) -t "localhost:5000/$(IMG_NAME)" .