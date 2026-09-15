resource "oci_identity_domains_identity_propagation_trust" "github" {
  provider = oci.home

  idcs_endpoint = local.terraform_identity_endpoint
  name          = "falco-github-terraform"
  description   = "GitHub-hosted Terraform workflow identity for Falco test-infra."
  schemas       = ["urn:ietf:params:scim:schemas:oracle:idcs:IdentityPropagationTrust"]
  type          = "JWT"
  active        = var.github_oidc_enabled

  issuer              = "https://token.actions.githubusercontent.com"
  public_key_endpoint = "https://token.actions.githubusercontent.com/.well-known/jwks"
  oauth_clients       = [var.github_oidc_client_id]
  client_claim_name   = "workflow_ref"
  client_claim_values = ["falcosecurity/test-infra/.github/workflows/terraform-oci.yml@refs/heads/master"]

  subject_claim_name  = "sub"
  subject_type        = "User"
  allow_impersonation = true

  dynamic "impersonation_service_users" {
    for_each = local.terraform_identities
    content {
      rule = join(" and ", [
        "sub eq 'repo:falcosecurity/test-infra:environment:oci-terraform-${impersonation_service_users.key}'",
        "aud eq 'https://cloud.oracle.com'",
        "ref eq 'refs/heads/master'",
        "runner_environment eq 'github-hosted'",
      ])
      value = oci_identity_domains_user.terraform[impersonation_service_users.key].id
    }
  }

  # Impersonation mappings are returned only when explicitly requested.
  attributes = join(",", [
    "id", "name", "description", "schemas", "type", "active", "issuer",
    "publicKeyEndpoint", "oauthClients", "clientClaimName", "clientClaimValues",
    "subjectClaimName", "subjectType", "allowImpersonation",
    "impersonationServiceUsers",
  ])

  lifecycle {
    prevent_destroy = true
  }
}
