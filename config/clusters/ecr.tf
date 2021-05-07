resource "aws_ecr_repository" "update_jobs" {
  name = "test-infra/update-jobs"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "golang" {
  name = "test-infra/golang"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "build_drivers" {
  name = "test-infra/build-drivers"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "docker_dind" {
  name = "test-infra/docker-dind"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "autobump" {
  name = "test-infra/autobump"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "arm_build" {
  name = "test-infra/arm-build"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "build_libs" {
  name = "test-infra/build-libs"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "update_deployment_files" {
  name = "test-infra/update-falco-k8s-manifests"
  encryption_configuration {
    encryption_type = "KMS"
  }
}
