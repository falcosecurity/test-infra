resource "oci_core_vcn" "this" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-vcn"
  freeform_tags  = local.tags
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-igw"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.tags
}

data "oci_core_services" "this" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

locals {
  # The filter above matches exactly one service set (the Oracle Services
  # Network supernet); one() fails the plan if it ever matches zero or several.
  oci_services_network_id   = one(data.oci_core_services.this.services[*].id)
  oci_services_network_cidr = one(data.oci_core_services.this.services[*].cidr_block)
}

resource "oci_core_service_gateway" "this" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-sgw"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.tags

  services {
    service_id = local.oci_services_network_id
  }
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-ngw"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.tags
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-public-routes"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.tags

  route_rules {
    description       = "Traffic to and from the internet."
    destination       = local.internet_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-private-routes"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.tags

  route_rules {
    description       = "Traffic to OCI services."
    destination       = local.oci_services_network_cidr
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this.id
  }

  route_rules {
    description       = "Egress traffic through NAT."
    destination       = local.internet_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this.id
  }
}

resource "oci_core_security_list" "kubernetes_api" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-k8s-api-seclist"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.tags

  egress_security_rules {
    description      = "Kubernetes API to worker nodes."
    destination      = var.node_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false
  }

  egress_security_rules {
    description      = "Kubernetes API to OCI services."
    destination      = local.oci_services_network_cidr
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = false

    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    description      = "Path discovery to worker nodes."
    destination      = var.node_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "1"
    stateless        = false

    icmp_options {
      type = 3
      code = 4
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.kubernetes_api_allowed_cidrs
    content {
      description = "External Kubernetes API access."
      protocol    = "6"
      source      = ingress_security_rules.value
      source_type = "CIDR_BLOCK"
      stateless   = false

      tcp_options {
        min = 6443
        max = 6443
      }
    }
  }

  ingress_security_rules {
    description = "Worker node access to Kubernetes API."
    protocol    = "6"
    source      = var.node_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    description = "Worker node to control plane communication."
    protocol    = "6"
    source      = var.node_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 12250
      max = 12250
    }
  }

  ingress_security_rules {
    description = "Path discovery from worker nodes."
    protocol    = "1"
    source      = var.node_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false

    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_security_list" "service_lb" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-service-lb-seclist"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.tags

  egress_security_rules {
    description      = "Load balancer kube-proxy health checks."
    destination      = var.node_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false

    tcp_options {
      min = 10256
      max = 10256
    }
  }

  egress_security_rules {
    description      = "Load balancer to NodePort services."
    destination      = var.node_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false

    tcp_options {
      min = 30000
      max = 32767
    }
  }

  dynamic "ingress_security_rules" {
    for_each = toset([80, 443, 8443])
    content {
      description = "Public service load balancer access."
      protocol    = "6"
      source      = local.internet_cidr
      source_type = "CIDR_BLOCK"
      stateless   = false

      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }
}

resource "oci_core_security_list" "node" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-node-seclist"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = local.tags

  egress_security_rules {
    description      = "Worker nodes to Kubernetes API."
    destination      = var.kubernetes_api_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    description      = "Worker nodes to control plane."
    destination      = var.kubernetes_api_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false

    tcp_options {
      min = 12250
      max = 12250
    }
  }

  egress_security_rules {
    description      = "Worker nodes to OCI services."
    destination      = local.oci_services_network_cidr
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = false

    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    description      = "Worker node pod-to-pod traffic."
    destination      = var.node_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  egress_security_rules {
    description      = "Worker node egress through NAT."
    destination      = local.internet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  egress_security_rules {
    description      = "Path discovery to Kubernetes API."
    destination      = var.kubernetes_api_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "1"
    stateless        = false

    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    description = "Worker node pod-to-pod traffic."
    protocol    = "all"
    source      = var.node_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    description = "Control plane to worker nodes."
    protocol    = "6"
    source      = var.kubernetes_api_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    description = "Path discovery from Kubernetes API."
    protocol    = "1"
    source      = var.kubernetes_api_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false

    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    description = "Service load balancer kube-proxy health checks."
    protocol    = "6"
    source      = var.service_lb_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 10256
      max = 10256
    }
  }

  ingress_security_rules {
    description = "Service load balancer NodePort access."
    protocol    = "6"
    source      = var.service_lb_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 30000
      max = 32767
    }
  }
}

resource "oci_core_subnet" "kubernetes_api" {
  cidr_block     = var.kubernetes_api_cidr
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-k8s-api-subnet"
  vcn_id         = oci_core_vcn.this.id

  route_table_id    = oci_core_route_table.public.id
  security_list_ids = [oci_core_security_list.kubernetes_api.id]
  freeform_tags     = local.tags
}

resource "oci_core_subnet" "service_lb" {
  cidr_block     = var.service_lb_cidr
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-service-lb-subnet"
  vcn_id         = oci_core_vcn.this.id

  route_table_id    = oci_core_route_table.public.id
  security_list_ids = [oci_core_security_list.service_lb.id]
  freeform_tags     = local.tags
}

resource "oci_core_subnet" "node" {
  cidr_block     = var.node_cidr
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-node-subnet"
  vcn_id         = oci_core_vcn.this.id

  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.node.id]
  freeform_tags              = local.tags
}
