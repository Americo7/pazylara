output "ctfd_vms_info" {
  description = "Información de las VMs de CTFD"
  value = {
    for i in range(length(openstack_compute_instance_v2.ctfd_vm)) : 
    "ctfd-vm-${i + 1}" => {
      name        = openstack_compute_instance_v2.ctfd_vm[i].name
      private_ip  = openstack_compute_instance_v2.ctfd_vm[i].network.0.fixed_ip_v4
      floating_ip = i < length(openstack_networking_floatingip_v2.ctfd_floating_ip) ? openstack_networking_floatingip_v2.ctfd_floating_ip[i].address : "No floating IP assigned"
      flavor      = "6 vCPUs, 6GB RAM, 50GB Disk"
    }
  }
}

output "web_challenges_vms_info" {
  description = "Información de las VMs de Web Challenges"
  value = {
    for i in range(length(openstack_compute_instance_v2.web_challenges_vm)) : 
    "web-challenges-vm-${i + 1}" => {
      name        = openstack_compute_instance_v2.web_challenges_vm[i].name
      private_ip  = openstack_compute_instance_v2.web_challenges_vm[i].network.0.fixed_ip_v4
      floating_ip = i < length(openstack_networking_floatingip_v2.web_challenges_floating_ip) ? openstack_networking_floatingip_v2.web_challenges_floating_ip[i].address : "No floating IP assigned"
      flavor      = "10 vCPUs, 8GB RAM, 50GB Disk"
    }
  }
}

output "vpn_vm_info" {
  description = "Información de la VM de VPN WireGuard"
  value = {
    name        = openstack_compute_instance_v2.vpn_vm.name
    private_ip  = openstack_compute_instance_v2.vpn_vm.network.0.fixed_ip_v4
    floating_ip = length(openstack_networking_floatingip_v2.vpn_floating_ip) > 0 ? openstack_networking_floatingip_v2.vpn_floating_ip[0].address : "No floating IP assigned"
    flavor      = "8 vCPUs, 8GB RAM, 30GB Disk"
  }
}

output "network_info" {
  description = "Información de la red creada"
  value = {
    network_name = openstack_networking_network_v2.ctfd_network.name
    network_id   = openstack_networking_network_v2.ctfd_network.id
    subnet_cidr  = openstack_networking_subnet_v2.ctfd_subnet.cidr
    router_name  = openstack_networking_router_v2.ctfd_router.name
  }
}

output "security_group_info" {
  description = "Información del security group"
  value = {
    name = openstack_networking_secgroup_v2.ctfd_secgroup.name
    id   = openstack_networking_secgroup_v2.ctfd_secgroup.id
  }
}

output "ssh_access_command" {
  description = "Comandos para acceder por SSH a las VMs"
  value = {
    ctfd_vms = [
      for i in range(length(openstack_compute_instance_v2.ctfd_vm)) :
      i < length(openstack_networking_floatingip_v2.ctfd_floating_ip) ? 
        "ssh -i ~/.ssh/id_rsa root@${openstack_networking_floatingip_v2.ctfd_floating_ip[i].address}" :
        "ssh -i ~/.ssh/id_rsa root@${openstack_compute_instance_v2.ctfd_vm[i].network.0.fixed_ip_v4} # Private IP only"
    ]
    web_challenges_vms = [
      for i in range(length(openstack_compute_instance_v2.web_challenges_vm)) :
      i < length(openstack_networking_floatingip_v2.web_challenges_floating_ip) ? 
        "ssh -i ~/.ssh/id_rsa root@${openstack_networking_floatingip_v2.web_challenges_floating_ip[i].address}" :
        "ssh -i ~/.ssh/id_rsa root@${openstack_compute_instance_v2.web_challenges_vm[i].network.0.fixed_ip_v4} # Private IP only"
    ]
    vpn_vm = length(openstack_networking_floatingip_v2.vpn_floating_ip) > 0 ? "ssh -i ~/.ssh/id_rsa root@${openstack_networking_floatingip_v2.vpn_floating_ip[0].address}" : "ssh -i ~/.ssh/id_rsa root@${openstack_compute_instance_v2.vpn_vm.network.0.fixed_ip_v4} # Private IP only"
  }
}

output "floating_ips_summary" {
  description = "Resumen de IPs flotantes asignadas"
  value = {
    ctfd_floating_ips          = [for ip in openstack_networking_floatingip_v2.ctfd_floating_ip : ip.address]
    web_challenges_floating_ips = [for ip in openstack_networking_floatingip_v2.web_challenges_floating_ip : ip.address]
    vpn_floating_ip            = length(openstack_networking_floatingip_v2.vpn_floating_ip) > 0 ? openstack_networking_floatingip_v2.vpn_floating_ip[0].address : "No floating IP"
    total_floating_ips_used    = length(openstack_networking_floatingip_v2.ctfd_floating_ip) + length(openstack_networking_floatingip_v2.web_challenges_floating_ip) + length(openstack_networking_floatingip_v2.vpn_floating_ip)
  }
}