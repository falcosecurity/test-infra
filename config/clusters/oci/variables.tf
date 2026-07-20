variable "auth" {
  description = "OCI Terraform provider authentication mode."
  type        = string
  default     = "APIKey"
}

variable "config_file_profile" {
  description = "OCI CLI config profile used for local bootstrap and first platform apply."
  type        = string
  default     = "FALCO_TEST_INFRA"
}

variable "region" {
  description = "OCI region where the Falco test-infra platform runs."
  type        = string
}

variable "home_region" {
  description = "OCI tenancy home region. Identity (dynamic group, policy, user) writes must target it."
  type        = string
}

variable "compartment_name" {
  description = "Name of the Falco test-infra compartment, used in IAM policy statements."
  type        = string
  default     = "falco-test-infra"
}

variable "tenancy_ocid" {
  description = "OCI tenancy OCID."
  type        = string
}

variable "compartment_ocid" {
  description = "OCI compartment OCID for Falco test-infra platform resources."
  type        = string
}

variable "object_storage_namespace" {
  description = "OCI Object Storage namespace used by platform resources."
  type        = string
}

variable "terraform_state_bucket_name" {
  description = "OCI Object Storage bucket used by this stack's Terraform backend."
  type        = string
}

variable "cluster_name" {
  description = "Name of the Falco OKE Prow cluster."
  type        = string
  default     = "falco-prow-test-infra-oci"
}

variable "control_plane_k8s_version" {
  description = "Kubernetes version for the OKE control plane."
  type        = string
  default     = "v1.35.0"
}

variable "nodepool_k8s_version" {
  description = "Kubernetes version for OKE node pools."
  type        = string
  default     = "v1.35.0"
}

variable "vcn_cidr" {
  description = "CIDR block for the OCI VCN."
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_api_cidr" {
  description = "CIDR block for the Kubernetes API endpoint subnet."
  type        = string
  default     = "10.0.0.0/28"
}

variable "service_lb_cidr" {
  description = "CIDR block for Kubernetes service load balancers."
  type        = string
  default     = "10.0.20.0/24"
}

variable "node_cidr" {
  description = "CIDR block for OKE worker nodes and pods."
  type        = string
  default     = "10.0.64.0/18"
}

variable "kubernetes_api_allowed_cidrs" {
  description = "CIDR blocks allowed to reach the public Kubernetes API endpoint."
  type        = list(string)
  default     = []
}

variable "allow_dynamic_node_images" {
  description = "Allow Terraform to select the latest non-GPU OKE image from OCI. Set to false and pin node_pool_image_ids before production apply."
  type        = bool
  default     = false
}

variable "node_pool_image_ids" {
  description = "Pinned OKE image OCIDs per architecture. Required for production applies unless allow_dynamic_node_images is true."
  type = object({
    x86 = optional(string)
    arm = optional(string)
  })
  default = {}
}

variable "node_pools" {
  description = "OKE node pools for Prow control plane, generic jobs, automation, and DriverKit workloads."
  type = map(object({
    arch              = string
    application       = string
    shape             = string
    ocpus             = number
    memory_gbs        = number
    boot_volume_gbs   = number
    size              = number
    autoscale         = bool
    autoscaler_min    = number
    autoscaler_max    = number
    preemptible       = optional(bool, false)
    max_pods_per_node = optional(number, 31)
    extra_labels      = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))

  default = {
    prow = {
      arch        = "x86"
      application = "platform"
      taints = [{
        key    = "dedicated.falco.org/platform"
        value  = "true"
        effect = "NoSchedule"
      }]
      shape           = "VM.Standard.E5.Flex"
      ocpus           = 2
      memory_gbs      = 16
      boot_volume_gbs = 100
      size            = 3
      autoscale       = false
      autoscaler_min  = 3
      autoscaler_max  = 3
    }
    jobs-x86 = {
      arch            = "x86"
      application     = "jobs"
      shape           = "VM.Standard.E5.Flex"
      ocpus           = 2
      memory_gbs      = 16
      boot_volume_gbs = 100
      size            = 1
      autoscale       = true
      autoscaler_min  = 1
      autoscaler_max  = 20
      preemptible     = true
    }
    jobs-arm = {
      arch        = "arm"
      application = "jobs"
      taints = [{
        key    = "Archtype"
        value  = "arm"
        effect = "NoSchedule"
      }]
      shape           = "VM.Standard.A1.Flex"
      ocpus           = 2
      memory_gbs      = 16
      boot_volume_gbs = 100
      size            = 1
      autoscale       = true
      autoscaler_min  = 1
      autoscaler_max  = 20
      preemptible     = true
    }
    automation = {
      arch        = "x86"
      application = "automation"
      taints = [{
        key    = "dedicated.falco.org/automation"
        value  = "true"
        effect = "NoSchedule"
      }]
      shape           = "VM.Standard.E6.Flex"
      ocpus           = 2
      memory_gbs      = 16
      boot_volume_gbs = 100
      size            = 1
      autoscale       = true
      autoscaler_min  = 1
      autoscaler_max  = 5
    }
    driverkit-x86 = {
      arch        = "x86"
      application = "driverkit"
      taints = [{
        key    = "dedicated.falco.org/driverkit"
        value  = "true"
        effect = "NoSchedule"
      }]
      shape           = "VM.Standard.E6.Flex"
      ocpus           = 8
      memory_gbs      = 48
      boot_volume_gbs = 200
      size            = 0
      autoscale       = true
      autoscaler_min  = 0
      autoscaler_max  = 4
    }
    driverkit-arm = {
      arch        = "arm"
      application = "driverkit"
      taints = [{
        key    = "dedicated.falco.org/driverkit"
        value  = "true"
        effect = "NoSchedule"
      }]
      shape           = "VM.Standard.A1.Flex"
      ocpus           = 8
      memory_gbs      = 48
      boot_volume_gbs = 200
      size            = 0
      autoscale       = true
      autoscaler_min  = 0
      autoscaler_max  = 4
    }
  }
}
