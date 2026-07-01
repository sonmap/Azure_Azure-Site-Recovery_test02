output "recovery_services_vault_id" {
  value = azurerm_recovery_services_vault.vault.id
}

output "cache_storage_account_id" {
  value = azurerm_storage_account.cache.id
}

output "asr_fabrics" {
  value = {
    source = azurerm_site_recovery_fabric.source.name
    target = azurerm_site_recovery_fabric.target.name
  }
}

output "replicated_vm_ids" {
  value = {
    for name, vm in azurerm_site_recovery_replicated_vm.vm : name => vm.id
  }
}
