data "azurerm_resource_group" "target_vm_rg" {
  for_each = local.target_resource_group_names

  name = each.key
}

# Source and target VNets are mapped by ASR so that failover can place the VM NIC into the DR VNet.
data "azurerm_virtual_network" "source" {
  name                = local.asr.source_vnet_name
  resource_group_name = local.asr.source_vnet_rg
}

data "azurerm_virtual_network" "target" {
  name                = local.asr.target_vnet_name
  resource_group_name = local.asr.target_vnet_rg
}
