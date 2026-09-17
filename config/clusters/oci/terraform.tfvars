region                      = "eu-frankfurt-1"
tenancy_ocid                = "ocid1.tenancy.oc1..aaaaaaaalp6ykyyigewiwa4tal7ygfiojduxkvmr7gwrlwdtudmhziuzgn2q"
compartment_ocid            = "ocid1.compartment.oc1..aaaaaaaah2q4x4h5ocavlv7lrjewexugllvvgn433vhseazfpkr6ivdju23q"
object_storage_namespace    = "idg4joojefiy"
terraform_state_bucket_name = "falco-test-infra-terraform-state"

control_plane_k8s_version = "v1.36.1"
nodepool_k8s_version      = "v1.36.1"

kubernetes_api_allowed_cidrs = ["0.0.0.0/0"]

# Pinned Oracle Linux 8.10 OKE-1.36.1 node images.
allow_dynamic_node_images = false
node_pool_image_ids = {
  x86 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa6w7ykf7q52bzogjtco5amiok2w7baaw2repr6qltymoue4sho6sq"
  arm = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaasawrlpp7oflhbezj4q3bfxgvt3rukuvhb2wfwjizqpsnz2v3ikja"
}
