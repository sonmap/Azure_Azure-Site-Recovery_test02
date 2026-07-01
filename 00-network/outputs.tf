output "resource_group_names" {
  value = keys(azurerm_resource_group.rg)
}

output "vnet_ids" {
  value = {
    for name, vnet in azurerm_virtual_network.vnet : name => vnet.id
  }
}

output "subnet_ids" {
  value = {
    for key, subnet in azurerm_subnet.subnet : key => subnet.id
  }
}

output "next_step_10_vm_network_reference" {
  value = {
    source_resource_group = "rg-asr-src-krc"
    source_vnet_name      = "vnet-asr-src-krc"
    source_subnet_name    = "snet-app"
    dr_resource_group     = "rg-asr-dr-jpe"
    dr_vnet_name          = "vnet-asr-dr-jpe"
    dr_subnet_name        = "snet-app"
    vault_resource_group  = "rg-asr-vault-jpe"
  }
}
