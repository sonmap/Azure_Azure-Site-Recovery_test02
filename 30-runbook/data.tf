data "azurerm_resource_group" "automation" {
  name = local.runbook.automation_rg
}

data "azurerm_resource_group" "vault" {
  name = local.runbook.vault_rg
}

data "azurerm_resource_group" "dr" {
  name = local.runbook.dr_resource_group_name
}
