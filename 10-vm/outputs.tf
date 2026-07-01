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

output "next_step_20_asr_protected_vms_csv" {
  value = "Copy vm_ids, vm_os_disk_ids, and vm_nic_ids into 20-asr/data/protected_vms.csv before applying 20-asr."
}
