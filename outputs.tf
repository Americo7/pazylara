output "instance_names" {
  description = "Nombres de las máquinas creadas"
  value       = [for vm in openstack_compute_instance_v2.vm : vm.name]
}
