locals {
  virtual_machines_raw = csvdecode(file("${path.module}/data/virtual_machines.csv"))

  virtual_machines = {
    for vm in local.virtual_machines_raw : vm.vm_name => merge(vm, {
      public_ip_enabled = lower(vm.public_ip_enabled) == "true"
    })
  }

  subnet_refs = toset([
    for vm in local.virtual_machines : "${vm.network_rg}|${vm.vnet_name}|${vm.subnet_name}"
  ])
}
