resource "aws_ecr_repository" "update_jobs" {
  name = "test-infra/update-jobs"
}

resource "aws_ecr_repository" "golang" {
  name = "test-infra/golang"
}

resource "aws_ecr_repository" "build_drivers" {
  name = "test-infra/build-drivers"
}

resource "aws_ecr_repository" "docker_dind" {
  name = "test-infra/docker-dind"
}

resource "aws_ecr_repository" "autobump" {
  name = "test-infra/autobump"
}

resource "aws_ecr_repository" "arm_build" {
  name = "test-infra/arm-build"
}

resource "aws_ecr_repository" "build_libs" {
  name = "test-infra/build-libs"
}
