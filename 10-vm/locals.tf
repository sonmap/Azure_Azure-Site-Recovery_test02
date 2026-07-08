locals {
  # Use the repository-level Azure-aligned inventory as the VM source of truth.
  # This replaces the older stack-local 10-vm/data/virtual_machines.csv input.
  virtual_machines_raw = csvdecode(file("${path.module}/../inventory/vm_inventory.csv"))

  virtual_machines = {
    for vm in local.virtual_machines_raw : vm.vm_name => merge(vm, {
      location            = vm.source_location
      resource_group_name = vm.source_resource_group
      network_rg          = vm.source_network_rg
      vnet_name           = vm.source_vnet_name
      subnet_name         = vm.source_subnet_name
      public_ip_enabled   = lower(vm.public_ip_enabled) == "true"
      asr_enabled         = lower(vm.asr_enabled) == "true"
      runbook_enabled     = lower(vm.runbook_enabled) == "true"
      failover_order      = tonumber(vm.failover_order)
    })
  }

  subnet_refs = toset([
    for vm in local.virtual_machines : "${vm.network_rg}|${vm.vnet_name}|${vm.subnet_name}"
  ])
}
