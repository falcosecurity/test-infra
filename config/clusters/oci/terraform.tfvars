region                      = "eu-frankfurt-1"
home_region                 = "us-ashburn-1"
tenancy_ocid                = "ocid1.tenancy.oc1..aaaaaaaalp6ykyyigewiwa4tal7ygfiojduxkvmr7gwrlwdtudmhziuzgn2q"
compartment_ocid            = "ocid1.compartment.oc1..aaaaaaaah2q4x4h5ocavlv7lrjewexugllvvgn433vhseazfpkr6ivdju23q"
object_storage_namespace    = "idg4joojefiy"
terraform_state_bucket_name = "falco-test-infra-terraform-state"

control_plane_k8s_version = "v1.35.2"
nodepool_k8s_version      = "v1.35.2"

kubernetes_api_allowed_cidrs = ["0.0.0.0/0"]

# Pinned Oracle Linux 8.10 OKE-1.35.2 node images.
allow_dynamic_node_images = false
node_pool_image_ids = {
  x86 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaav2jmtlvaol3i6mo3knbx6k2r4kphghs2a3wkubvnvmaoprbopoyq"
  arm = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaavbppmhyt3phoh4ibbgvf5zwzppmqc5gc46py5tp7imjrt2p5yqqa"
}
