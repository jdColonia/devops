# 1. Workshop - Terraform

## First Part: Azure Function Implementation

### Overview

This section describes the deployment process of an Azure Function using Terraform. The necessary resources are configured, including a resource group, a storage account, a service plan, and the function application itself. Subsequently, Terraform commands are executed to deploy the infrastructure on Azure and verify its functionality.

### Solution

This workshop is based on the repository `https://github.com/ChristianFlor/azfunction-tf.git`, which provides a detailed structure of the code used. The subscription used for this deployment is of the "educational" type, which requires specifying the subscription key (which can be retrieved using `az account show`).

#### Files and Configuration

1. **main.tf**: Contains the main Terraform configuration to deploy resources on Azure.
2. **outputs.tf**: Defines the output of the Terraform execution, such as the deployed Azure Function URL.
3. **variables.tf**: Stores reusable variables like the function name and region.
4. **terraform.tfvars** _(missing)_: Should contain the concrete values for the variables.

##### `main.tf`

- **Terraform Provider (`provider`)**: Specifies that Azure will be used as the infrastructure provider. The `features {}` configuration is mandatory but can be left empty. The Azure subscription key must be provided.

```HCL
provider "azurerm" {
  features {}
  subscription_id = ""
}
```

- **Resource Group (`azurerm_resource_group`)**: A container for the infrastructure resources in Azure. It is defined with a specified name and location using variables.

```HCL
resource "azurerm_resource_group" "rg" {
  name     = var.name_function
  location = var.location
}
```

- **Storage Account (`azurerm_storage_account`)**: Azure Functions requires a storage account to manage files and logs. It is defined with a "Standard" service tier and "LRS" (Locally Redundant Storage) replication.

```HCL
resource "azurerm_storage_account" "sa" {
  name                     = var.name_function
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

- **Service Plan (`azurerm_service_plan`)**: Defines the execution plan type for the Function App. The "Y1" (Consumption) plan is set for automatic scaling and pay-per-execution.

```HCL
resource "azurerm_service_plan" "sp" {
  name                = var.name_function
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "Y1"
}
```

- **Azure Function App (`azurerm_windows_function_app`)**: Configures the function application, linking it to the storage and service plan. The Node.js version to be used is also specified.

```HCL
resource "azurerm_windows_function_app" "wfa" {
  name                = var.name_function
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.sp.id

  site_config {
    application_stack {
      node_version = "~18"
    }
  }
}
```

- **Function Definition (`azurerm_function_app_function`)**: Creates a function within the Function App. This function is written in JavaScript and loads an `index.js` file with the function logic.

```HCL
resource "azurerm_function_app_function" "faf" {
  name            = var.name_function
  function_app_id = azurerm_windows_function_app.wfa.id
  language        = "Javascript"

  file {
    name    = "index.js"
    content = file("example/index.js")
  }

  test_data = jsonencode({
    "name" = "Azure"
  })

  config_json = jsonencode({
    "bindings" : [
      {
        "authLevel" : "anonymous",
        "type" : "httpTrigger",
        "direction" : "in",
        "name" : "req",
        "methods" : ["get", "post"]
      },
      {
        "type" : "http",
        "direction" : "out",
        "name" : "res"
      }
    ]
  })
}
```

##### `outputs.tf`

Defines the Terraform output, in this case, the invocation URL of the function.

```HCL
output "url" {
  value       = azurerm_function_app_function.faf.invocation_url
  sensitive   = false
  description = "description"
}
```

##### `variables.tf`

Defines reusable variables for the infrastructure.

```HCL
variable "name_function" {
  type        = string
  description = "Name Function"
}

variable "location" {
  type        = string
  default     = "West Europe"
  description = "Location"
}
```

> [!IMPORTANT]
> The file `terraform.tfvars` is missing, which should specify the values for the variables.

#### Proceso de despliegue con Terraform

1. Initialize the working directory with Terraform using `terraform init`. This downloads the required providers and configures the backend for state storage.

   ![Image](./images/Pasted%20image%2020250316201300.png)

2. Validate that the configuration is syntactically correct and that references to resources and providers are valid using `terraform validate`.

   ![Image](./images/Pasted%20image%2020250316201344.png)

3. Execute `terraform plan` to preview the changes that will be applied to the infrastructure. This allows reviewing what resources will be created, modified, or deleted without executing changes.

   ![Image](./images/Pasted%20image%2020250316202232.png)

4. Apply the defined changes in the configuration using `terraform apply`, which creates, modifies, or deletes the resources. Once the infrastructure is deployed, Azure's platform can be accessed to verify the created resources.

   ![Image](./images/Pasted%20image%2020250314122242.png)

5. To test the function, access the URL provided by Azure and append `/api/functionName` to execute it.

   ![Image](./images/Pasted%20image%2020250314122158.png)

> [!Warning]
> Do not forget to delete the infrastructure with `terraform destroy` to avoid unnecessary costs on Azure.

## Second Part: Deployment of a Linux Virtual Machine

### Overview

This section describes how Terraform is used to provision a virtual machine with a Linux operating system in Azure. The infrastructure defined in the `main.tf` file includes a virtual network, a subnet, a network interface, and a virtual machine. However, after executing Terraform initially, it was detected that the virtual machine had no public access and did not allow external connections. To resolve this, additional resources were added: a public IP address, a network security group, and the association between this group and the network interface.

### Solution

#### Files and Configuration

##### `main.tf`

- **Terraform Provider (`provider`)**

```HCL
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
```

- **Resource Group (`azurerm_resource_group`)**

```HCL
resource "azurerm_resource_group" "vm_rg" {
  name     = var.resource_group_name
  location = var.location
}
```

- **Virtual Network and Subnet (`azurerm_virtual_network`,`azurerm_subnet`)**: Defines a virtual network with an IP address space and a subnet within that network. The subnet is used to assign IP addresses to connected resources, such as the virtual machine's network interface.

```HCL
resource "azurerm_virtual_network" "vm_vnet" {
  name                = var.vnet_name
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.vm_rg.name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = [var.subnet_address_prefix]
}
```

- **Network Interface (`azurerm_network_interface`)**: Creates a network interface that connects the virtual machine to the previously defined subnet.

```HCL
resource "azurerm_network_interface" "vm_nic" {
  name                = var.nic_name
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
```

- **Linux Virtual Machine (`azurerm_linux_virtual_machine`)**: Defines the virtual machine with a Linux operating system. It specifies details such as the VM size, administrator username and password, and the operating system image (in this case, Ubuntu Server 22.04 LTS). The VM is associated with the previously created network interface.

```HCL
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = azurerm_resource_group.vm_rg.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
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

##### `variables.tf`

Defines reusable variables for the infrastructure.

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
```

##### `outputs.tf`

For now, the `outputs.tf` file will remain empty.

##### `terraform.tfvars`

Defines the specific values of the variables used in the configuration.

```HCL
subscription_id = ""
admin_password = "password12345!"
```

#### Infrastructure Deployment

The infrastructure deployment follows the standard Terraform process (`terraform init`, `terraform validate`, `terraform plan` and `terraform apply`).

![Image](./images/Pasted%20image%2020250317211418.png)

After the initial deployment, the resources were successfully created.

![Image](./images/Pasted%20image%2020250317211247.png)

However, upon accessing the VM, it was observed that the virtual machine had no public access nor an open port for SSH connections, preventing remote access.

![Image](./images/Pasted%20image%2020250317211335.png)
![Image](./images/Pasted%20image%2020250317211527.png)

#### Solution to Connectivity Issue

To resolve the connectivity issue, the following resources were added to the `main.tf` file:

- **Network Security Group (NSG) with SSH rule (`azurerm_network_security_group`)**: Creates a network security group with a rule allowing SSH traffic (port 22) from any IP address.

```HCL
resource "azurerm_network_security_group" "vm_nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

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
```

- **NSG Association with the NIC (`azurerm_network_interface_security_group_association`)**: Associates the network security group with the virtual machine's network interface to apply the security rules.

```HCL
resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}
```

- **Public IP Address (`azurerm_public_ip`)**: Creates a public IP address to allow remote access to the virtual machine.

```HCL
resource "azurerm_public_ip" "vm_public_ip" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = azurerm_resource_group.vm_rg.location
  allocation_method   = "Static"
}
```

- The network interface is modified to associate it with the public IP address (`public_ip_address_id`).

```HCL
resource "azurerm_network_interface" "vm_nic" {
  name                = var.nic_name
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}
```

In the `variables.tf` file, a variable for the network security group name is added.

```HCL
variable "nsg_name" {
  type    = string
  default = "vm_nsg"
}
```

Finally, in the `outputs.tf` file, the following is added:

```HCL
output "public_ip" {
  value = azurerm_public_ip.vm_public_ip.ip_address
}
```

#### Validation and VM Connection

After applying the changes, the infrastructure is updated with `terraform apply`.

![Image](./images/Pasted%20image%2020250317212142.png)
![Image](./images/Pasted%20image%2020250317212338.png)

The public IP address of the virtual machine can be obtained using the command `terraform output public_ip`.

![Image](./images/Pasted%20image%2020250317212747.png)

Finally, the virtual machine is accessed using SSH.

![Image](./images/Pasted%20image%2020250317213004.png)

> [!Warning]
> Do not forget to destroy the infrastructure with `terraform destroy` to avoid unnecessary costs in Azure.
