
# pazylara

Ejemplo de configuración de Terraform para desplegar cuatro máquinas virtuales en OpenStack.

## Uso

1. Instala [Terraform](https://www.terraform.io/downloads.html).
2. Crea un archivo `terraform.tfvars` con los valores de las variables requeridas:

```hcl
auth_url       = "https://openstack.example.com:5000/v3"
user_name      = "usuario"
password       = "contraseña"
tenant_name    = "proyecto"
region         = "RegionOne"
image_name     = "ubuntu-22.04"
flavor_name    = "m1.small"
key_pair       = "mi-keypair"
security_groups = ["default"]
network_name   = "red-privada"
```
3. Inicializa el directorio y valida la configuración:

```bash
terraform init -backend=false
terraform validate
```
4. Despliega las máquinas:

```bash
terraform apply
```
=======
# AMERICO GEY

