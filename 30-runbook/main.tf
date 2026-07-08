resource "azurerm_automation_account" "asr" {
  name                = local.runbook.automation_account_name
  location            = local.runbook.location
  resource_group_name = local.runbook.automation_rg
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    managed_by = "terraform"
    purpose    = "asr-automation-runbook"
  }
}

# Lab-oriented permissions. For production, reduce this to the minimum required ASR and target RG permissions.
resource "azurerm_role_assignment" "vault_contributor" {
  scope                = data.azurerm_resource_group.vault.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.asr.identity[0].principal_id
}

resource "azurerm_role_assignment" "dr_contributor" {
  scope                = data.azurerm_resource_group.dr.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.asr.identity[0].principal_id
}

resource "azurerm_automation_runbook" "asr_failover" {
  name                    = "Invoke-AsrFailover"
  location                = azurerm_automation_account.asr.location
  resource_group_name     = azurerm_automation_account.asr.resource_group_name
  automation_account_name = azurerm_automation_account.asr.name

  log_verbose  = true
  log_progress = true

  runbook_type = "PowerShell"
  description  = "Azure Site Recovery status, test failover, cleanup, and failover runbook."

  content = file("${path.module}/runbooks/Invoke-AsrFailover.ps1")
}
