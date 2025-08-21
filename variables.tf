variable "allowed_ips" {
  description = "Lista de IPs permitidas para acceder a las máquinas virtuales"
  type        = list(string)
  default = [
    "192.168.24.74",
    "192.168.24.89",
    "192.168.24.68",
    "192.168.24.29"
  ]
}

variable "floating_ips" {
  description = "IPs flotantes específicas para asignar a las VMs (vacío = sin IP flotante)"
  type = object({
    ctfd           = list(string)
    web_challenges = list(string)
    vpn           = string
  })
  default = {
    ctfd = [
      "10.188.105.131",  # CTFD VM 1 - sin IP flotante
      "10.188.105.132"   # CTFD VM 2 - sin IP flotante
    ]
    web_challenges = [
      "10.188.105.133",  # Web Challenges VM 1 - sin IP flotante
      "10.188.105.134"   # Web Challenges VM 2 - sin IP flotante
    ]
    vpn = "10.188.105.100"  # VPN VM - con IP flotante
  }
}

variable "private_ips" {
  description = "IPs privadas específicas para las VMs en la red interna"
  type = object({
    ctfd           = list(string)
    web_challenges = list(string)
    vpn           = string
  })
  default = {
    ctfd = [
      "10.0.1.11",  # CTFD VM 1
      "10.0.1.12"   # CTFD VM 2
    ]
    web_challenges = [
      "10.0.1.13",  # Web Challenges VM 1
      "10.0.1.14"   # Web Challenges VM 2
    ]
    vpn = "10.0.1.15"  # VPN VM
  }
}

variable "users" {
  description = "Usuarios que tendrán acceso a las VMs"
  type = map(object({
    name = string
    ip   = string
  }))
  default = {
    "franz" = {
      name = "Franz Rojas"
      ip   = "192.168.24.74"
    }
    "rodrigo" = {
      name = "Rodrigo Uruchi"
      ip   = "192.168.24.89"
    }
    "ricardo" = {
      name = "Ricardo Chavez"
      ip   = "192.168.24.68"
    }
  }
}