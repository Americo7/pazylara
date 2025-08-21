terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
}

provider "openstack" {
  auth_url    = var.auth_url
  user_name   = var.user_name
  password    = var.password
  tenant_name = var.tenant_name
  region      = var.region
}

resource "openstack_compute_instance_v2" "vm" {
  count = 4
  name  = "vm-${count.index + 1}"

  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = var.key_pair

  security_groups = var.security_groups

  network {
    name = var.network_name
  }
}
