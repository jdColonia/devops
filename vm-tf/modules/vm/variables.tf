variable "resource_group_name" {
  type    = string
  default = "vm_rg"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "subnet_id" {
  type = string
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
