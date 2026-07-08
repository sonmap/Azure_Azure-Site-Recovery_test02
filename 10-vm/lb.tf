resource "azurerm_lb" "app_internal" {
  name                = "ilb-asr-app-krc"
  location            = local.primary_app_vm.location
  resource_group_name = local.primary_app_vm.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "fe-app"
    subnet_id                     = data.azurerm_subnet.subnet[local.primary_app_subnet_ref].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    managed_by = "terraform"
    purpose    = "asr-dr-lab"
    role       = "internal-load-balancer"
    note       = "vm-ha-front-end"
  }
}

resource "azurerm_lb_backend_address_pool" "app" {
  name            = "be-tomcat-8080"
  loadbalancer_id = azurerm_lb.app_internal.id
}

resource "azurerm_lb_probe" "tomcat" {
  name            = "probe-tomcat-8080"
  loadbalancer_id = azurerm_lb.app_internal.id
  protocol        = "Tcp"
  port            = 8080
}

resource "azurerm_lb_rule" "tomcat" {
  name                           = "rule-tomcat-8080"
  loadbalancer_id                = azurerm_lb.app_internal.id
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "fe-app"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app.id]
  probe_id                       = azurerm_lb_probe.tomcat.id
  load_distribution              = "Default"
}

resource "azurerm_network_interface_backend_address_pool_association" "app" {
  for_each = local.primary_app_vms

  network_interface_id    = azurerm_network_interface.nic[each.key].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.app.id
}
