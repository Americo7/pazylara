terraform {
  required_version = ">= 1.3.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53"
    }
  }
}

provider "openstack" {
  cloud = "openstack"
}

locals {
  allowed_ips = [for u in var.users : u.ip]

  vm_instances = flatten([
    for group_name, group in var.vm_groups : [
      for inst_name, inst in group.instances : {
        key         = "${group_name}-${inst_name}"
        group       = group_name
        name        = "${group_name}-vm-${inst_name}"
        private_ip  = inst.private_ip
        floating_ip = inst.floating_ip
      }
    ]
  ])

  vm_instances_map = { for inst in local.vm_instances : inst.key => inst }
}

resource "openstack_networking_network_v2" "network" {
  name           = var.network.name
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "subnet" {
  name            = var.network.subnet_name
  network_id      = openstack_networking_network_v2.network.id
  cidr            = var.network.cidr
  ip_version      = 4
  dns_nameservers = var.network.dns_servers
}

data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

resource "openstack_networking_router_v2" "router" {
  name                = var.network.router_name
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

resource "openstack_compute_flavor_v2" "flavor" {
  for_each = var.vm_groups

  name      = "${each.key}-flavor"
  ram       = each.value.flavor.ram
  vcpus     = each.value.flavor.vcpus
  disk      = each.value.flavor.disk
  is_public = true
}

data "openstack_images_image_v2" "debian12" {
  name        = "Debian-12-Generic"
  most_recent = true
}

resource "openstack_networking_secgroup_v2" "secgroup" {
  name        = "ctfd-secgroup"
  description = "Security group for CTFD infrastructure"
}

resource "openstack_networking_secgroup_rule_v2" "ingress_self_ipv4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  remote_group_id   = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "ingress_self_ipv6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  remote_group_id   = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "tcp_ipv4_any_from_allowed" {
  count             = length(local.allowed_ips)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = format("%s/32", local.allowed_ips[count.index])
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "udp_ipv4_any_from_allowed" {
  count             = length(local.allowed_ips)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = format("%s/32", local.allowed_ips[count.index])
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "wireguard_any" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 51820
  port_range_max    = 51820
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_compute_instance_v2" "vm" {
  for_each        = local.vm_instances_map
  name            = each.value.name
  image_id        = data.openstack_images_image_v2.debian12.id
  flavor_id       = openstack_compute_flavor_v2.flavor[each.value.group].id
  key_pair        = null
  security_groups = [openstack_networking_secgroup_v2.secgroup.name]
  user_data       = file("cloud-init.yaml")

  network {
    name        = openstack_networking_network_v2.network.name
    fixed_ip_v4 = each.value.private_ip
  }

  depends_on = [openstack_networking_router_interface_v2.router_interface]
}

resource "openstack_networking_floatingip_v2" "fip" {
  for_each = { for k, v in local.vm_instances_map : k => v if v.floating_ip != "" }

  pool    = var.external_network_name
  address = each.value.floating_ip
}

resource "openstack_compute_floatingip_associate_v2" "fip_assoc" {
  for_each = openstack_networking_floatingip_v2.fip

  floating_ip = each.value.address
  instance_id = openstack_compute_instance_v2.vm[each.key].id
}
