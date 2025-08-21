variable "auth_url" {
  description = "URL de autenticación de OpenStack"
  type        = string
}

variable "user_name" {
  description = "Usuario de OpenStack"
  type        = string
}

variable "password" {
  description = "Contraseña de OpenStack"
  type        = string
}

variable "tenant_name" {
  description = "Proyecto o tenant de OpenStack"
  type        = string
}

variable "region" {
  description = "Región de OpenStack"
  type        = string
}

variable "image_name" {
  description = "Nombre de la imagen a usar"
  type        = string
}

variable "flavor_name" {
  description = "Nombre del flavor de la instancia"
  type        = string
}

variable "key_pair" {
  description = "Nombre del par de claves a usar"
  type        = string
}

variable "security_groups" {
  description = "Lista de grupos de seguridad"
  type        = list(string)
  default     = ["default"]
}

variable "network_name" {
  description = "Nombre de la red a la que conectarse"
  type        = string
}
