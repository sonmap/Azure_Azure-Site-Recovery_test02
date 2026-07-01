resource "azurerm_resource_group" "rg" {
  for_each = local.resource_groups

  name     = each.value.resource_group_name
  location = each.value.location

  tags = {
    environment = each.value.environment
    owner       = each.value.owner
    managed_by  = "terraform"
    purpose     = "asr-dr-lab"
  }
}

resource "azurerm_virtual_network" "vnet" {
  for_each = local.vnets

  name                = each.value.vnet_name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  address_space       = each.value.address_space
  dns_servers         = each.value.dns_servers

  tags = {
    managed_by  = "terraform"
    purpose     = "asr-dr-lab"
    description = each.value.description
  }

  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_subnet" "subnet" {
  for_each = local.subnets

  name                 = each.value.subnet_name
  resource_group_name  = each.value.resource_group_name
  virtual_network_name = each.value.vnet_name
  address_prefixes     = each.value.address_prefixes

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_network_security_group" "nsg" {
  for_each = local.nsgs

  name                = each.value.nsg_name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  tags = {
    managed_by  = "terraform"
    purpose     = "asr-dr-lab"
    description = each.value.description
  }

  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_network_security_rule" "rule" {
  for_each = local.nsg_rules

  name                        = each.value.rule_name
  priority                    = tonumber(each.value.priority)
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = local.nsgs[each.value.nsg_name].resource_group_name
  network_security_group_name = each.value.nsg_name
  description                 = each.value.description

  depends_on = [
    azurerm_network_security_group.nsg
  ]
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  for_each = {
    for key, subnet in local.subnets : key => subnet
    if length(trimspace(subnet.nsg_name)) > 0
  }

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg_name].id
}
