output "automation_account_name" {
  value = azurerm_automation_account.asr.name
}

output "automation_principal_id" {
  value = azurerm_automation_account.asr.identity[0].principal_id
}

output "runbook_name" {
  value = azurerm_automation_runbook.asr_failover.name
}

output "runbook_vault_reference" {
  value = {
    vault_resource_group = local.runbook.vault_rg
    vault_name           = local.runbook.vault_name
  }
}
