region       = "eu-frankfurt-1"
home_region  = "us-ashburn-1"
tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaalp6ykyyigewiwa4tal7ygfiojduxkvmr7gwrlwdtudmhziuzgn2q"

# Leave true for a brand-new tenancy setup.
create_compartment = true
compartment_name   = "falco-test-infra"

terraform_state_bucket_name = "falco-test-infra-terraform-state"

github_oidc_client_id = "718a53d715f549aca624c028ede41440"
github_oidc_enabled   = false

oke_cluster_ocid = "ocid1.cluster.oc1.eu-frankfurt-1.aaaaaaaarclidxnact4h4lh55xvyaxuibzcpmqeordimlfnvycuiycvgt3ca"
