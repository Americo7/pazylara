terraform {
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

# Crear la red privada
resource "openstack_networking_network_v2" "ctfd_network" {
  name           = "ctfd-network"
  admin_state_up = "true"
}

# Crear la subred
resource "openstack_networking_subnet_v2" "ctfd_subnet" {
  name       = "ctfd-subnet"
  network_id = openstack_networking_network_v2.ctfd_network.id
  cidr       = "10.0.1.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Obtener la red externa
data "openstack_networking_network_v2" "external" {
  name = "red_externa_01"
}

# Crear el router
resource "openstack_networking_router_v2" "ctfd_router" {
  name                = "ctfd-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

# Conectar la subred al router
resource "openstack_networking_router_interface_v2" "ctfd_router_interface" {
  router_id = openstack_networking_router_v2.ctfd_router.id
  subnet_id = openstack_networking_subnet_v2.ctfd_subnet.id
}

# Crear flavors personalizados
resource "openstack_compute_flavor_v2" "ctfd_flavor" {
  name      = "ctfd-flavor"
  ram       = "6144"
  vcpus     = "6"
  disk      = "50"
  is_public = "true"
}

resource "openstack_compute_flavor_v2" "web_challenges_flavor" {
  name      = "web-challenges-flavor"
  ram       = "8192"
  vcpus     = "10"
  disk      = "50"
  is_public = "true"
}

resource "openstack_compute_flavor_v2" "vpn_flavor" {
  name      = "vpn-flavor"
  ram       = "8192"
  vcpus     = "8"
  disk      = "30"
  is_public = "true"
}

# Obtener la imagen de Debian 12
data "openstack_images_image_v2" "debian12" {
  name        = "Debian-12-Generic"
  most_recent = true
}

# Crear security group
resource "openstack_networking_secgroup_v2" "ctfd_secgroup" {
  name        = "ctfd-secgroup"
  description = "Security group for CTFD infrastructure"
}

# 1) INGRESS desde el mismo SG (lo que en Horizon se ve como remote: default)
resource "openstack_networking_secgroup_rule_v2" "ingress_self_ipv4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.ctfd_secgroup.id
  remote_group_id   = openstack_networking_secgroup_v2.ctfd_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "ingress_self_ipv6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.ctfd_secgroup.id
  remote_group_id   = openstack_networking_secgroup_v2.ctfd_secgroup.id
}



# 3) TCP SOLO desde IPs permitidas (IPv4)
resource "openstack_networking_secgroup_rule_v2" "tcp_ipv4_any_from_allowed" {
  count             = length(var.allowed_ips)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "${var.allowed_ips[count.index]}/32"
  security_group_id = openstack_networking_secgroup_v2.ctfd_secgroup.id
}

# 3.5) UDP SOLO desde IPs permitidas (IPv4)
resource "openstack_networking_secgroup_rule_v2" "udp_ipv4_any_from_allowed" {
  count             = length(var.allowed_ips)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "${var.allowed_ips[count.index]}/32"
  security_group_id = openstack_networking_secgroup_v2.ctfd_secgroup.id
}

# 3) ICMP (ping) SOLO desde IPs permitidas (IPv4)
resource "openstack_networking_secgroup_rule_v2" "icmp_ipv4_restricted" {
  count             = length(var.allowed_ips)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  # Deja sin port_range_min/max para permitir todos los tipos/códigos ICMP
  remote_ip_prefix  = "${var.allowed_ips[count.index]}/32"
  security_group_id = openstack_networking_secgroup_v2.ctfd_secgroup.id
}

# 4) HTTP/HTTPS abiertos al mundo (si así lo necesitas para CTFD)
resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ctfd_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ctfd_secgroup.id
}

# (Opcional) WireGuard: puedes mantenerlo abierto o restringirlo también a allowed_ips
resource "openstack_networking_secgroup_rule_v2" "wireguard_any" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 51820
  port_range_max    = 51820
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ctfd_secgroup.id
}

# VMs para CTFD (2 máquinas) con IPs específicas
resource "openstack_compute_instance_v2" "ctfd_vm" {
  count           = 2
  name            = "ctfd-vm-${count.index + 1}"
  image_id        = data.openstack_images_image_v2.debian12.id
  flavor_id       = openstack_compute_flavor_v2.ctfd_flavor.id
  key_pair        = null  # Las claves SSH se configuran via cloud-init
  security_groups = [openstack_networking_secgroup_v2.ctfd_secgroup.name]
  user_data       = file("cloud-init.yaml")

  network {
    name        = openstack_networking_network_v2.ctfd_network.name
    fixed_ip_v4 = var.private_ips.ctfd[count.index]
  }

  depends_on = [openstack_networking_router_interface_v2.ctfd_router_interface]
}

# VMs para Web Challenges (2 máquinas) con IPs específicas
resource "openstack_compute_instance_v2" "web_challenges_vm" {
  count           = 2
  name            = "web-challenges-vm-${count.index + 1}"
  image_id        = data.openstack_images_image_v2.debian12.id
  flavor_id       = openstack_compute_flavor_v2.web_challenges_flavor.id
  key_pair        = null  # Las claves SSH se configuran via cloud-init
  security_groups = [openstack_networking_secgroup_v2.ctfd_secgroup.name]
  user_data       = file("cloud-init.yaml")

  network {
    name        = openstack_networking_network_v2.ctfd_network.name
    fixed_ip_v4 = var.private_ips.web_challenges[count.index]
  }

  depends_on = [openstack_networking_router_interface_v2.ctfd_router_interface]
}

# VM para VPN WireGuard con IP específica
resource "openstack_compute_instance_v2" "vpn_vm" {
  name            = "vpn-wireguard-vm"
  image_id        = data.openstack_images_image_v2.debian12.id
  flavor_id       = openstack_compute_flavor_v2.vpn_flavor.id
  key_pair        = null  # Las claves SSH se configuran via cloud-init
  security_groups = [openstack_networking_secgroup_v2.ctfd_secgroup.name]
  user_data       = file("cloud-init.yaml")

  network {
    name        = openstack_networking_network_v2.ctfd_network.name
    fixed_ip_v4 = var.private_ips.vpn
  }

  depends_on = [openstack_networking_router_interface_v2.ctfd_router_interface]
}

# Floating IPs condicionales - solo se crean si se especifica una IP
resource "openstack_networking_floatingip_v2" "ctfd_floating_ip" {
  count   = length([for ip in var.floating_ips.ctfd : ip if ip != ""])
  pool    = "red_externa_01"
  address = [for ip in var.floating_ips.ctfd : ip if ip != ""][count.index]
}

resource "openstack_networking_floatingip_v2" "web_challenges_floating_ip" {
  count   = length([for ip in var.floating_ips.web_challenges : ip if ip != ""])
  pool    = "red_externa_01"
  address = [for ip in var.floating_ips.web_challenges : ip if ip != ""][count.index]
}

resource "openstack_networking_floatingip_v2" "vpn_floating_ip" {
  count   = var.floating_ips.vpn != "" ? 1 : 0
  pool    = "red_externa_01"
  address = var.floating_ips.vpn
}

# Asociar floating IPs a las VMs - solo si existen
resource "openstack_compute_floatingip_associate_v2" "ctfd_fip_associate" {
  count       = length(openstack_networking_floatingip_v2.ctfd_floating_ip)
  floating_ip = openstack_networking_floatingip_v2.ctfd_floating_ip[count.index].address
  instance_id = openstack_compute_instance_v2.ctfd_vm[count.index].id
}

resource "openstack_compute_floatingip_associate_v2" "web_challenges_fip_associate" {
  count       = length(openstack_networking_floatingip_v2.web_challenges_floating_ip)
  floating_ip = openstack_networking_floatingip_v2.web_challenges_floating_ip[count.index].address
  instance_id = openstack_compute_instance_v2.web_challenges_vm[count.index].id
}

resource "openstack_compute_floatingip_associate_v2" "vpn_fip_associate" {
  count       = length(openstack_networking_floatingip_v2.vpn_floating_ip)
  floating_ip = openstack_networking_floatingip_v2.vpn_floating_ip[0].address
  instance_id = openstack_compute_instance_v2.vpn_vm.id
}