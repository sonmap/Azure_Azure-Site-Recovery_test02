data "azurerm_subnet" "subnet" {
  for_each = local.subnet_refs

  name                 = split("|", each.value)[2]
  virtual_network_name = split("|", each.value)[1]
  resource_group_name  = split("|", each.value)[0]
}
