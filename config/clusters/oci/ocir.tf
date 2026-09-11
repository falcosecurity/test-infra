# OCIR repositories for test-infra CI images.
locals {
  ocir_repositories = [
    "build-drivers",
    "build-plugins",
    "docker-dind",
    "ghissue",
    "golang",
    "sync-charts",
    "update-dbg",
    "update-falco-k8s-manifests",
    "update-jobs",
    "update-maintainers",
    "update-rules-index",
  ]
}

resource "oci_artifacts_container_repository" "test_infra" {
  for_each = toset(local.ocir_repositories)

  compartment_id = var.compartment_ocid
  display_name   = "test-infra/${each.key}"
  is_immutable   = false
  is_public      = false
  freeform_tags  = local.tags
}
