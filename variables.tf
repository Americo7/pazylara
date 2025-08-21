variable "network" {
  description = "Configuración de la red interna y el router"
  type = object({
    name        = string
    subnet_name = string
    router_name = string
    cidr        = string
    dns_servers = list(string)
  })
  default = {
    name        = "ctfd-network"
    subnet_name = "ctfd-subnet"
    router_name = "ctfd-router"
    cidr        = "10.0.1.0/24"
    dns_servers = ["8.8.8.8", "8.8.4.4"]
  }
}

variable "external_network_name" {
  description = "Nombre de la red externa para IPs flotantes"
  type        = string
  default     = "red_externa_01"
}

variable "users" {
  description = "Usuarios que tendrán acceso a las VMs (se derivan las IPs permitidas)"
  type = map(object({
    name = string
    ip   = string
  }))
  default = {
    franz = {
      name = "Franz Rojas"
      ip   = "192.168.24.74"
    }
    rodrigo = {
      name = "Rodrigo Uruchi"
      ip   = "192.168.24.89"
    }
    ricardo = {
      name = "Ricardo Chavez"
      ip   = "192.168.24.68"
    }
  }
}

variable "vm_groups" {
  description = "Configuración de VMs agrupadas por entorno"
  type = map(object({
    flavor = object({
      ram   = number
      vcpus = number
      disk  = number
    })
    instances = map(object({
      private_ip  = string
      floating_ip = string
    }))
  }))
  default = {
    ctfd = {
      flavor = { ram = 6144, vcpus = 6, disk = 50 }
      instances = {
        "1" = { private_ip = "10.0.1.11", floating_ip = "" }
        "2" = { private_ip = "10.0.1.12", floating_ip = "" }
      }
    }
    web = {
      flavor = { ram = 8192, vcpus = 10, disk = 50 }
      instances = {
        "1" = { private_ip = "10.0.1.13", floating_ip = "" }
        "2" = { private_ip = "10.0.1.14", floating_ip = "" }
      }
    }
    vpn = {
      flavor = { ram = 8192, vcpus = 8, disk = 30 }
      instances = {
        "1" = { private_ip = "10.0.1.15", floating_ip = "10.188.105.100" }
      }
    }
  }
}
