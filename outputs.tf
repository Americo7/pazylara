output "vm_info" {
  description = "Información de las VMs desplegadas"
  value = {
    for k, inst in openstack_compute_instance_v2.vm :
    k => {
      name        = inst.name
      private_ip  = inst.network[0].fixed_ip_v4
      floating_ip = try(openstack_networking_floatingip_v2.fip[k].address, "No floating IP assigned")
      flavor = format("%d vCPUs, %dMB RAM, %dGB Disk",
        openstack_compute_flavor_v2.flavor[local.vm_instances_map[k].group].vcpus,
        openstack_compute_flavor_v2.flavor[local.vm_instances_map[k].group].ram,
      openstack_compute_flavor_v2.flavor[local.vm_instances_map[k].group].disk)
    }
  }
}

output "network_info" {
  description = "Información de la red creada"
  value = {
    network_name = openstack_networking_network_v2.network.name
    network_id   = openstack_networking_network_v2.network.id
    subnet_cidr  = openstack_networking_subnet_v2.subnet.cidr
    router_name  = openstack_networking_router_v2.router.name
  }
}

output "security_group_info" {
  description = "Información del security group"
  value = {
    name = openstack_networking_secgroup_v2.secgroup.name
    id   = openstack_networking_secgroup_v2.secgroup.id
  }
}

output "ssh_access_commands" {
  description = "Comandos para acceder por SSH a las VMs"
  value = {
    for k, inst in openstack_compute_instance_v2.vm :
    k => (contains(keys(openstack_networking_floatingip_v2.fip), k) ?
      "ssh -i ~/.ssh/id_rsa root@${openstack_networking_floatingip_v2.fip[k].address}" :
    "ssh -i ~/.ssh/id_rsa root@${inst.network[0].fixed_ip_v4} # Private IP only")
  }
}

output "floating_ips_summary" {
  description = "Resumen de IPs flotantes asignadas"
  value = {
    for k, fip in openstack_networking_floatingip_v2.fip :
    k => fip.address
  }
}
