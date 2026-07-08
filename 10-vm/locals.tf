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

  app_vms = {
    for name, vm in local.virtual_machines : name => vm
    if vm.role == "app"
  }

  primary_app_vms = {
    for name, vm in local.app_vms : name => vm
    if vm.environment != "dr"
  }

  primary_app_vm = tolist(values(local.primary_app_vms))[0]

  primary_app_subnet_ref = "${local.primary_app_vm.network_rg}|${local.primary_app_vm.vnet_name}|${local.primary_app_vm.subnet_name}"

  subnet_refs = toset([
    for vm in local.virtual_machines : "${vm.network_rg}|${vm.vnet_name}|${vm.subnet_name}"
  ])
}
