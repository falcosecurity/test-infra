locals {
  platform_state_key = "platform.tfstate"

  terraform_read_permissions = [
    "read clusters",
    "read cluster-node-pools",
    "read cluster-work-requests",
    "inspect instances",
    "read virtual-network-family",
    "read log-groups",
    "read repos",
  ]

  terraform_apply_permissions = [
    "manage clusters",
    "manage cluster-node-pools",
    "manage instance-family",
    "manage virtual-network-family",
    "manage log-groups",
    "manage repos",
  ]
}

# GetNodePoolOptions with a compartment filter requires COMPARTMENT_INSPECT.
resource "oci_identity_policy" "terraform_compartment" {
  for_each = local.terraform_identities
  provider = oci.home

  compartment_id = var.tenancy_ocid
  name           = "${each.value}-compartment"
  description    = "Allow Terraform ${each.key} to discover the platform compartment."
  freeform_tags  = var.tags

  statements = [
    "Allow group id ${oci_identity_group.terraform[each.key].id} to inspect compartments in tenancy where target.compartment.id = '${local.platform_compartment_id}'",
  ]
}

resource "oci_identity_policy" "terraform_platform" {
  for_each = local.terraform_identities
  provider = oci.home

  compartment_id = local.platform_compartment_id
  name           = "${each.value}-platform"
  description    = "Platform Terraform ${each.key} permissions and scoped backend access."
  freeform_tags  = var.tags

  statements = concat(
    [for permission in local.terraform_read_permissions :
      "Allow group id ${oci_identity_group.terraform[each.key].id} to ${permission} in compartment id ${local.platform_compartment_id}"
    ],
    [
      # The kubeconfig data source needs CLUSTER_USE for this API operation.
      "Allow group id ${oci_identity_group.terraform[each.key].id} to use clusters in compartment id ${local.platform_compartment_id} where request.operation = 'CreateKubeconfig'",
    ],
    [for bucket in [var.terraform_state_bucket_name, var.prow_logs_bucket_name] :
      "Allow group id ${oci_identity_group.terraform[each.key].id} to read buckets in compartment id ${local.platform_compartment_id} where target.bucket.name = '${bucket}'"
    ],
    [
      # Backend workspace discovery lists names; object contents stay scoped.
      "Allow group id ${oci_identity_group.terraform[each.key].id} to inspect objects in compartment id ${local.platform_compartment_id} where target.bucket.name = '${var.terraform_state_bucket_name}'",
    ],
    [for key in [local.platform_state_key, "${local.platform_state_key}.lock"] :
      "Allow group id ${oci_identity_group.terraform[each.key].id} to read objects in compartment id ${local.platform_compartment_id} where all {target.bucket.name = '${var.terraform_state_bucket_name}', target.object.name = '${key}'}"
    ],
    [for operation in ["PutObject", "DeleteObject"] :
      "Allow group id ${oci_identity_group.terraform[each.key].id} to manage objects in compartment id ${local.platform_compartment_id} where all {target.bucket.name = '${var.terraform_state_bucket_name}', target.object.name = '${local.platform_state_key}.lock', request.operation = '${operation}'}"
    ],
    each.key == "apply" ? concat(
      [for permission in local.terraform_apply_permissions :
        "Allow group id ${oci_identity_group.terraform[each.key].id} to ${permission} in compartment id ${local.platform_compartment_id}"
      ],
      [
        "Allow group id ${oci_identity_group.terraform[each.key].id} to manage buckets in compartment id ${local.platform_compartment_id} where target.bucket.name = '${var.prow_logs_bucket_name}'",
        # Lifecycle configuration requires object permissions, not only BUCKET_UPDATE.
        "Allow group id ${oci_identity_group.terraform[each.key].id} to manage objects in compartment id ${local.platform_compartment_id} where all {target.bucket.name = '${var.prow_logs_bucket_name}', request.operation = 'PutObjectLifecyclePolicy'}",
        # State writes do not grant deletion of the state or its prior versions.
        "Allow group id ${oci_identity_group.terraform[each.key].id} to manage objects in compartment id ${local.platform_compartment_id} where all {target.bucket.name = '${var.terraform_state_bucket_name}', target.object.name = '${local.platform_state_key}', request.operation = 'PutObject'}",
      ],
    ) : [],
  )
}
