data "oci_identity_domains" "default" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  state          = "ACTIVE"
  type           = "DEFAULT"
}

resource "oci_identity_domains_user" "prow_logs" {
  provider      = oci.home
  active        = true
  idcs_endpoint = one(data.oci_identity_domains.default.domains).url
  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:userState:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:capabilities:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:user:User",
  ]
  user_name = "falco-prow-logs"

  name {
    family_name = "Prow logs"
  }

  emails {
    primary = true
    type    = "work"
    value   = "poiana.bot@gmail.com"
  }

  emails {
    primary = false
    type    = "recovery"
    value   = "poiana.bot@gmail.com"
  }

  urnietfparamsscimschemasoracleidcsextensioncapabilities_user {
    can_use_api_keys                 = false
    can_use_auth_tokens              = false
    can_use_console                  = false
    can_use_console_password         = false
    can_use_customer_secret_keys     = true
    can_use_db_credentials           = false
    can_use_oauth2client_credentials = false
    can_use_smtp_credentials         = false
  }

  urnietfparamsscimschemasoracleidcsextensionuser_user {
    service_user = false
  }
}

resource "oci_identity_group" "prow_logs_writers" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = "falco-prow-logs-writers"
  description    = "Principals allowed to access the Prow log and artifact bucket."
  freeform_tags  = local.platform_tags
}

resource "oci_identity_user_group_membership" "prow_logs" {
  provider = oci.home
  group_id = oci_identity_group.prow_logs_writers.id
  user_id  = oci_identity_domains_user.prow_logs.ocid
}

resource "oci_identity_policy" "prow_logs" {
  provider       = oci.home
  compartment_id = local.platform_compartment_id
  name           = "falco-prow-logs-access"
  description    = "Allow Prow to access only its log and artifact bucket."
  freeform_tags  = local.platform_tags

  statements = [
    "Allow group id ${oci_identity_group.prow_logs_writers.id} to read buckets in compartment id ${local.platform_compartment_id} where target.bucket.name = '${var.prow_logs_bucket_name}'",
    "Allow group id ${oci_identity_group.prow_logs_writers.id} to manage objects in compartment id ${local.platform_compartment_id} where target.bucket.name = '${var.prow_logs_bucket_name}'",
  ]
}
