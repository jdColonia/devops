output "vnet_id" {
  value = azurerm_virtual_network.vm_vnet.id
}

output "subnet_id" {
  value = azurerm_subnet.vm_subnet.id
}
