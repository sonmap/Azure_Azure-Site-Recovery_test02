data "azurerm_subnet" "subnet" {
  for_each = local.subnet_refs

  resource_group_name  = split("|", each.key)[0]
  virtual_network_name = split("|", each.key)[1]
  name                 = split("|", each.key)[2]
}
