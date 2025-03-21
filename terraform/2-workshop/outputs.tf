output "resource_group_id" {
  value = module.resource_group.resource_group_id
}

output "public_ip" {
  value = module.vm.public_ip
}

output "vm_id" {
  value = module.vm.vm_id
}
