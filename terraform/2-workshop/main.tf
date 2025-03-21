provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "resource_group" {
  source              = "./modules/resource_group"
  resource_group_name = var.resource_group_name
  location            = var.location
}

module "network" {
  source                = "./modules/network"
  resource_group_name   = module.resource_group.resource_group_name
  location              = module.resource_group.resource_group_location
  vnet_name             = var.vnet_name
  vnet_address_space    = var.vnet_address_space
  subnet_name           = var.subnet_name
  subnet_address_prefix = var.subnet_address_prefix
}

module "security" {
  source              = "./modules/security"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  nsg_name            = var.nsg_name
  nic_id              = module.vm.nic_id
}

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
