locals {
  terraform_identity_endpoint = trimsuffix(one(data.oci_identity_domains.default.domains).url, ":443")

  terraform_identities = {
    plan  = "falco-terraform-plan"
    apply = "falco-terraform-apply"
  }
}

resource "oci_identity_domains_user" "terraform" {
  for_each = local.terraform_identities
  provider = oci.home

  idcs_endpoint = local.terraform_identity_endpoint
  user_name     = each.value
  active        = true
  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:userState:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:capabilities:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:user:User",
  ]
  attributes = join(",", [
    "id", "ocid", "userName", "active", "schemas",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:userState:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:capabilities:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:user:User.serviceUser",
  ])

  urnietfparamsscimschemasoracleidcsextensioncapabilities_user {
    can_use_api_keys                 = false
    can_use_auth_tokens              = false
    can_use_console_password         = false
    can_use_customer_secret_keys     = false
    can_use_db_credentials           = false
    can_use_oauth2client_credentials = false
    can_use_smtp_credentials         = false
  }

  urnietfparamsscimschemasoracleidcsextensionuser_user {
    service_user = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_identity_group" "terraform" {
  for_each = local.terraform_identities
  provider = oci.home

  compartment_id = var.tenancy_ocid
  name           = each.value
  description    = "GitHub-hosted Terraform ${each.key} identity for Falco test-infra."
  freeform_tags  = var.tags
}

resource "oci_identity_user_group_membership" "terraform" {
  for_each = local.terraform_identities
  provider = oci.home

  group_id = oci_identity_group.terraform[each.key].id
  user_id  = oci_identity_domains_user.terraform[each.key].ocid
}
