output "vm_ids" {
  value = {
    for name, vm in azurerm_linux_virtual_machine.vm : name => vm.id
  }
}

output "vm_os_disk_ids" {
  value = {
    for name, vm in azurerm_linux_virtual_machine.vm : name => vm.os_disk[0].managed_disk_id
  }
}

output "vm_nic_ids" {
  value = {
    for name, nic in azurerm_network_interface.nic : name => nic.id
  }
}

output "private_ip_addresses" {
  value = {
    for name, nic in azurerm_network_interface.nic : name => nic.private_ip_address
  }
}

output "internal_load_balancer_private_ip" {
  value = azurerm_lb.app_internal.frontend_ip_configuration[0].private_ip_address
}

output "internal_load_balancer_backend_pool_id" {
  value = azurerm_lb_backend_address_pool.app.id
}

output "next_step_20_asr_protected_vms_csv" {
  value = "Run python3 scripts/generate_protected_vms.py to generate 20-asr/data/protected_vms.csv from inventory and Terraform outputs."
}
