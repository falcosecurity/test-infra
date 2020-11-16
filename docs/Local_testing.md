# Local Prow Testing

We can locally test prowjobs using `KIND` before we make a PR. There are some limitations to tests, such that we cannot use AWS credentials so we cannot do

- Container Build Pushes
- Anything leveraging AWS CLI

## Local Prow Script

Located at `tools/local_prowjob_test.sh` the local script will do

1. Create a local docker registry at `localhost:5000`
2. Build local container and push to local registry
3. Spin up Local Kind Cluster, and patch to work on Prow
4. Build Prowjob, using local image as job image.
5. Run Prowjob, and report status.

## Testing Build-Drivers Prowjob locally

1. Build local image, and push to local registry. 

```
IMG_NAME = test-infra/build-drivers
ACCOUNT=292999226676
DOCKER_PUSH_REPOSITORY=dkr.ecr.eu-west-1.amazonaws.com
TAG?=latest
IMAGE=$(ACCOUNT).$(DOCKER_PUSH_REPOSITORY)/$(IMG_NAME)

local-registry:
	docker tag $(IMAGE):$(TAG) localhost:5000/build-drivers
	docker push localhost:5000/build-drivers
```
Here we have our makefile, and can go into our image folder, and run `make local-registry`, or run the commands yourself.

2. Build Prowjob local file, replacing image with our new `localhost:5000` image.

Here we create a new file 

`config/jobs/build-drivers/build-drivers.local`
```yaml
  falcosecurity/test-infra:
  - name: build-drivers-amazonlinux-presubmit
    decorate: true
    skip_report: false
    agent: kubernetes
    branches:
      - ^master$
    spec:
      containers:
      - command:
        - /workspace/build-drivers.sh
        - amazonlinux
        env:
        - name: AWS_REGION
          value: eu-west-1
        image: localhost:5000/build-drivers #changed to local build
        imagePullPolicy: Always
        securityContext:
          privileged: true
```

3. Go to `tools/local_prowjob_test.sh` and change these 3 values.

```bash
export CONFIG_PATH="$(pwd)/config/config.yaml"

export JOB_CONFIG_PATH="$(pwd)/config/jobs/build-drivers/build-drivers.local"

export IMAGE_PATH="$(pwd)/images/build-drivers"
#Skip this if not performing image build in script
```

4. Run the script with the name of job to test, as the arguement.  `./tools/local_prowjob_test.sh build-drivers-amazonlinux-presubmit`


5. This will write the new cluster as your current Kube Config, and you can check the logs of your running job.


You can see the KIND cluster spin up, and begin to run the tests.

[local](docs/images/local-testing.png)



## Cleanup of local testing

Run the cleanup script, or delete the registry and kind cluster yourself.

`./tools/delete_local_prowjob_test.sh`

```bash
set -o errexit

# desired cluster name; default is "kind"
KIND_CLUSTER_NAME="mkpod"

kind_network='bridge'
reg_name='kind-registry'
reg_port='5000'

# create registry container unless it already exists
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" == 'true' ]; then
  cid="$(docker inspect -f '{{.ID}}' "${reg_name}")"
  echo "> Stopping and deleting Kind Registry container..."
  docker stop $cid >/dev/null
  docker rm $cid >/dev/null
fi

echo "> Deleting Kind cluster..."
kind delete cluster --name=$KIND_CLUSTER_NAME
```



