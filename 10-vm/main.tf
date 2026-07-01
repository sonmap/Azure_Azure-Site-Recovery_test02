resource "azurerm_public_ip" "pip" {
  for_each = {
    for name, vm in local.virtual_machines : name => vm
    if vm.public_ip_enabled
  }

  name                = "pip-${each.value.vm_name}"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    managed_by = "terraform"
    purpose    = "asr-dr-lab"
  }
}

resource "azurerm_network_interface" "nic" {
  for_each = local.virtual_machines

  name                = "nic-${each.value.vm_name}"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.subnet["${each.value.network_rg}|${each.value.vnet_name}|${each.value.subnet_name}"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.value.public_ip_enabled ? azurerm_public_ip.pip[each.key].id : null
  }

  tags = {
    managed_by = "terraform"
    purpose    = "asr-dr-lab"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = local.virtual_machines

  name                = each.value.vm_name
  computer_name       = each.value.computer_name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  size                = each.value.vm_size
  admin_username      = each.value.admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    name                 = "${each.value.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
  }

  source_image_reference {
    publisher = each.value.image_publisher
    offer     = each.value.image_offer
    sku       = each.value.image_sku
    version   = each.value.image_version
  }

  tags = {
    managed_by  = "terraform"
    purpose     = "asr-dr-lab"
    replication = "asr-source"
  }
}
