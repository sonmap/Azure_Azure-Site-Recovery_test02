resource "azurerm_recovery_services_vault" "vault" {
  name                = local.asr.vault_name
  location            = local.asr.vault_location
  resource_group_name = local.asr.vault_resource_group_name
  sku                 = "Standard"

  soft_delete_enabled = false

  tags = {
    managed_by = "terraform"
    purpose    = "asr-dr-lab"
  }
}

resource "azurerm_storage_account" "cache" {
  name                     = local.asr.cache_storage_account_name
  resource_group_name      = local.asr.cache_resource_group_name
  location                 = local.asr.cache_location
  account_tier             = local.asr.cache_account_tier
  account_replication_type = local.asr.cache_replication_type
  account_kind             = "StorageV2"

  min_tls_version = "TLS1_2"

  tags = {
    managed_by = "terraform"
    purpose    = "asr-cache"
  }
}

resource "azurerm_site_recovery_fabric" "source" {
  name                = local.asr.source_fabric_name
  resource_group_name = local.asr.vault_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  location            = local.asr.source_location
}

resource "azurerm_site_recovery_fabric" "target" {
  name                = local.asr.target_fabric_name
  resource_group_name = local.asr.vault_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  location            = local.asr.target_location
}

resource "azurerm_site_recovery_protection_container" "source" {
  name                 = local.asr.source_protection_container_name
  resource_group_name  = local.asr.vault_resource_group_name
  recovery_vault_name  = azurerm_recovery_services_vault.vault.name
  recovery_fabric_name = azurerm_site_recovery_fabric.source.name
}

resource "azurerm_site_recovery_protection_container" "target" {
  name                 = local.asr.target_protection_container_name
  resource_group_name  = local.asr.vault_resource_group_name
  recovery_vault_name  = azurerm_recovery_services_vault.vault.name
  recovery_fabric_name = azurerm_site_recovery_fabric.target.name
}

resource "azurerm_site_recovery_replication_policy" "policy" {
  name                                                 = local.asr.replication_policy_name
  resource_group_name                                  = local.asr.vault_resource_group_name
  recovery_vault_name                                  = azurerm_recovery_services_vault.vault.name
  recovery_point_retention_in_minutes                  = local.asr.recovery_point_retention_in_minutes
  application_consistent_snapshot_frequency_in_minutes = local.asr.application_consistent_snapshot_frequency_in_minutes
}

resource "azurerm_site_recovery_protection_container_mapping" "container_mapping" {
  name                                      = "mapping-${local.asr.source_location}-to-${local.asr.target_location}"
  resource_group_name                       = local.asr.vault_resource_group_name
  recovery_vault_name                       = azurerm_recovery_services_vault.vault.name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.source.name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.source.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.target.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id
}

resource "azurerm_site_recovery_network_mapping" "network_mapping" {
  name                        = "mapping-${local.asr.source_vnet_name}-to-${local.asr.target_vnet_name}"
  resource_group_name         = local.asr.vault_resource_group_name
  recovery_vault_name         = azurerm_recovery_services_vault.vault.name
  source_recovery_fabric_name = azurerm_site_recovery_fabric.source.name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.target.name
  source_network_id           = data.azurerm_virtual_network.source.id
  target_network_id           = data.azurerm_virtual_network.target.id
}

resource "azurerm_site_recovery_replicated_vm" "vm" {
  for_each = local.protected_vms

  name                                      = each.value.replication_name
  resource_group_name                       = local.asr.vault_resource_group_name
  recovery_vault_name                       = azurerm_recovery_services_vault.vault.name
  source_recovery_fabric_name               = azurerm_site_recovery_fabric.source.name
  source_vm_id                              = each.value.source_vm_id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id
  source_recovery_protection_container_name = azurerm_site_recovery_protection_container.source.name

  target_resource_group_id                = data.azurerm_resource_group.target_vm_rg[each.value.target_resource_group_name].id
  target_recovery_fabric_id               = azurerm_site_recovery_fabric.target.id
  target_recovery_protection_container_id = azurerm_site_recovery_protection_container.target.id
  target_network_id                       = data.azurerm_virtual_network.target.id
  target_subnet_name                      = each.value.target_subnet_name
  target_vm_name                          = each.value.target_vm_name

  managed_disk {
    disk_id                    = each.value.os_disk_id
    staging_storage_account_id = azurerm_storage_account.cache.id
    target_resource_group_id   = data.azurerm_resource_group.target_vm_rg[each.value.target_resource_group_name].id
    target_disk_type           = each.value.target_disk_type
    target_replica_disk_type   = each.value.target_replica_disk_type
  }

  depends_on = [
    azurerm_site_recovery_protection_container_mapping.container_mapping,
    azurerm_site_recovery_network_mapping.network_mapping
  ]
}
