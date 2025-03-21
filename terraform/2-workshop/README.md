# 2. Workshop - Terraform

## Despliegue de una Máquina Virtual Linux usando Módulos

### Resumen

En este informe, se utiliza Terraform para aprovisionar una máquina virtual con sistema operativo Linux en Azure. Para lograrlo, se utiliza la configuración de la infraestructura del workshop anterior (`https://github.com/jdColonia/devops/tree/main/terraform/1-workshop`) añadiendo módulos a la estructura del proyecto, facilitando la gestión y mantenimiento de la infraestructura.

### Solución

#### Estructura del proyecto

El proyecto está organizado en una estructura de directorios que separa los diferentes componentes de la infraestructura en módulos. Cada módulo contiene sus propios archivos de configuración (`main.tf`, `variables.tf`, y `outputs.tf`), lo que facilita la reutilización y el mantenimiento del código.

```plaintext
/
|-- main.tf
|-- variables.tf
|-- outputs.tf
|-- terraform.tfvars
|-- modules/
    |-- resource_group/
        |-- main.tf
        |-- variables.tf
        |-- outputs.tf
    |-- network/
        |-- main.tf
        |-- variables.tf
        |-- outputs.tf
    |-- security/
        |-- main.tf
        |-- variables.tf
        |-- outputs.tf
    |-- vm/
        |-- main.tf
        |-- variables.tf
        |-- outputs.tf
```

- **Módulo `resource_group`**: Encargado de crear un grupo de recursos en Azure.
- **Módulo `network`**: Define la red virtual y la subred donde se desplegará la máquina virtual.
- **Módulo `security`**: Configura un grupo de seguridad de red (NSG) con reglas para permitir el tráfico SSH.
- **Módulo `vm`**: Crea la máquina virtual, la interfaz de red y la dirección IP pública.

#### Archivos y Configuración

##### `main.tf`

El archivo `main.tf` en la raíz del proyecto define los módulos y sus dependencias. Aquí se especifica el proveedor de Azure y se invocan los módulos para crear los recursos necesarios.

- **Proveedor de Terraform (`provider`)**:

```HCL
provider "azurerm" {
	features {}
	subscription_id = var.subscription_id
}
```

- **Módulo `resource_group`**:

```HCL
module "resource_group" {
	source              = "./modules/resource_group"
	resource_group_name = var.resource_group_name
	location            = var.location
}
```

- **Módulo `network`**:

```HCL
module "network" {
	source                = "./modules/network"
	resource_group_name   = module.resource_group.resource_group_name
	location              = module.resource_group.resource_group_location
	vnet_name             = var.vnet_name
	vnet_address_space    = var.vnet_address_space
	subnet_name           = var.subnet_name
	subnet_address_prefix = var.subnet_address_prefix
}
```

- **Módulo `security`**:

```HCL
module "security" {
	source              = "./modules/security"
	resource_group_name = module.resource_group.resource_group_name
	location            = module.resource_group.resource_group_location
	nsg_name            = var.nsg_name
	nic_id              = module.vm.nic_id
}
```

- **Módulo `vm`**:

```hcl
module "vm" {
	source              = "./modules/vm"
	resource_group_name = module.resource_group.resource_group_name
	location            = module.resource_group.resource_group_location
	nic_name            = var.nic_name
	public_ip_name      = var.public_ip_name
	vm_name             = var.vm_name
	vm_size             = var.vm_size
	admin_username      = var.admin_username
	admin_password      = var.admin_password
	subnet_id           = module.network.subnet_id
}
```

##### `variables.tf`

El archivo `variables.tf` de la raíz del proyecto define TODAS las variables utilizadas en la configuración de Terraform y deben poder mapearse desde cada uno de los módulos.

```HCL
variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type    = string
  default = "vm_rg"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "vnet_name" {
  type    = string
  default = "vm_vnet"
}

variable "vnet_address_space" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_name" {
  type    = string
  default = "vm_subnet"
}

variable "subnet_address_prefix" {
  type    = string
  default = "10.0.2.0/24"
}

variable "nic_name" {
  type    = string
  default = "vm_nic"
}

variable "public_ip_name" {
  type    = string
  default = "vm_public_ip"
}

variable "vm_name" {
  type    = string
  default = "vm"
}

variable "vm_size" {
  type    = string
  default = "Standard_F2"
}

variable "admin_username" {
  type    = string
  default = "adminuser"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "nsg_name" {
  type    = string
  default = "vm_nsg"
}
```

##### `outputs.tf`

El archivo `outputs.tf` define las salidas que se pueden consultar después de aplicar la configuración de Terraform. Estas salidas incluyen el ID del grupo de recursos, la dirección IP pública de la máquina virtual y el ID de la máquina virtual.

```HCL
output "resource_group_id" {
  value = module.resource_group.resource_group_id
}

output "public_ip" {
  value = module.vm.public_ip
}

output "vm_id" {
  value = module.vm.vm_id
}
```

##### `terraform.tfvars`

El archivo `terraform.tfvars` contiene los valores concretos de las variables definidas en `variables.tf`. Aquí se especifica el ID de la suscripción de Azure y la contraseña del usuario administrador de la máquina virtual.

```HCL
subscription_id = ""
admin_password  = "password12345!"
```

##### Módulos

###### Módulo `resource_group`

Este módulo crea un grupo de recursos en Azure. El grupo de recursos es un contenedor lógico que agrupa los recursos relacionados con la solución.

- **`main.tf`**:

```HCL
resource "azurerm_resource_group" "vm_rg" {
	name     = var.resource_group_name
	location = var.location
}
```

- **`variables.tf`**:

```HCL
variable "resource_group_name" {
	type        = string
}

variable "location" {
	type        = string
}
```

- **`outputs.tf`**:

```HCL
output "resource_group_name" {
	value       = azurerm_resource_group.vm_rg.name
}

output "resource_group_location" {
	value       = azurerm_resource_group.vm_rg.location
}

output "resource_group_id" {
	value       = azurerm_resource_group.vm_rg.id
}
```

###### Módulo `network`

Este módulo define la red virtual y la subred donde se desplegará la máquina virtual.

- **`main.tf`**:

```HCL
resource "azurerm_virtual_network" "vm_vnet" {
	name                = var.vnet_name
	address_space       = [var.vnet_address_space]
	location            = var.location
	resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "vm_subnet" {
	name                 = var.subnet_name
	resource_group_name  = var.resource_group_name
	virtual_network_name = azurerm_virtual_network.vm_vnet.name
	address_prefixes     = [var.subnet_address_prefix]
}
```

- **`variables.tf`**:

```HCL
variable "resource_group_name" {
	type = string
}

variable "location" {
	type = string
}

variable "vnet_name" {
	type = string
}

variable "vnet_address_space" {
	type = string
}

variable "subnet_name" {
	type = string
}

variable "subnet_address_prefix" {
	type = string
}
```

- **`outputs.tf`**:

```HCL
output "vnet_id" {
	value = azurerm_virtual_network.vm_vnet.id
}

output "subnet_id" {
	value = azurerm_subnet.vm_subnet.id
}
```

###### Módulo `security`

Este módulo configura un grupo de seguridad de red (NSG) con una regla que permite el tráfico SSH desde cualquier dirección IP. Además, asocia el NSG con la interfaz de red de la máquina virtual.

- **`main.tf`**:

```HCL
resource "azurerm_network_security_group" "vm_nsg" {
	name                = var.nsg_name
	location            = var.location
	resource_group_name = var.resource_group_name

	security_rule {
      name                       = "ssh_rule"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
	}
}

resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
	network_interface_id      = var.nic_id
	network_security_group_id = azurerm_network_security_group.vm_nsg.id
}
```

- **`variables.tf`**:

```HCL
variable "resource_group_name" {
	type = string
}

variable "location" {
	type = string
}

variable "nsg_name" {
	type = string
}

variable "nic_id" {
	type = string
}
```

- **`outputs.tf`**:

```HCL
output "nsg_id" {
	value = azurerm_network_security_group.vm_nsg.id
}
```

###### Módulo `vm`

Este módulo crea la máquina virtual, la interfaz de red y la dirección IP pública. La máquina virtual se configura con una imagen de Ubuntu Server 22.04 LTS y se asocia con la interfaz de red y la subred definidas anteriormente.

- **`main.tf`**:

```HCL
resource "azurerm_public_ip" "vm_public_ip" {
	name                = var.public_ip_name
	resource_group_name = var.resource_group_name
	location            = var.location
	allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm_nic" {
	name                = var.nic_name
	location            = var.location
	resource_group_name = var.resource_group_name

	ip_configuration {
      name                          = "internal"
      subnet_id                     = var.subnet_id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
	}
}

resource "azurerm_linux_virtual_machine" "vm" {
	name                  = var.vm_name
	resource_group_name   = var.resource_group_name
	location              = var.location
	size                  = var.vm_size
	admin_username        = var.admin_username
	admin_password        = var.admin_password
	network_interface_ids = [azurerm_network_interface.vm_nic.id]

	os_disk {
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
	}

	source_image_reference {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts"
      version   = "latest"
	}

	disable_password_authentication = false
	provision_vm_agent              = true
}
```

- **`variables.tf`**:

```HCL
variable "resource_group_name" {
	type = string
}

variable "location" {
	type = string
}

variable "nic_name" {
	type = string
}

variable "public_ip_name" {
	type = string
}

variable "vm_name" {
	type = string
}

variable "vm_size" {
	type = string
}

variable "admin_username" {
	type = string
}

variable "admin_password" {
	type      = string
	sensitive = true
}

variable "subnet_id" {
	type = string
}
```

- **`outputs.tf`**:

```HCL
output "vm_id" {
	value = azurerm_linux_virtual_machine.vm.id
}

output "public_ip" {
	value = azurerm_public_ip.vm_public_ip.ip_address
}

output "nic_id" {
	value = azurerm_network_interface.vm_nic.id
}
```

#### Despliegue de Infraestructura

El despliegue de la infraestructura sigue el proceso estándar de Terraform:

1. **Inicialización**: `terraform init` para descargar los proveedores y módulos necesarios.

   ![Images](./images/Pasted%20image%2020250321004615.png)

2. **Validación**: `terraform validate` para verificar la sintaxis y configuración.

   ![Images](./images/Pasted%20image%2020250321005143.png)

3. **Planificación**: `terraform plan` para revisar los cambios que se aplicarán.

   ![Images](./images/Pasted%20image%2020250321005204.png)

4. **Aplicación**: `terraform apply` para crear los recursos en Azure.

   ![Images](./images/Pasted%20image%2020250321011128.png)

Tras el despliegue, la máquina virtual estará disponible con una dirección IP pública que permitirá el acceso remoto a través de SSH.

![Images](./images/Pasted%20image%2020250321012849.png)

> [!Warning]
> No olvidar eliminar la infraestructura con `terraform destroy` para evitar costos innecesarios en Azure.
