# Major BUG: OpenRemote software is showing wrong redirect URL when deployed with private VM setup

resource "azurerm_public_ip" "openremote-lb-ip" {
  count               = var.enable_private_vm_setup ? 1 : 0
  name                = "openremote-lb-ip"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  location            = azurerm_resource_group.openremote-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "load_balancer" {
  count               = var.enable_private_vm_setup ? 1 : 0
  name                = "openremote-lb"
  location            = azurerm_resource_group.openremote-rg.location
  resource_group_name = azurerm_resource_group.openremote-rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.openremote-lb-ip[count.index].id
  }
}

resource "azurerm_lb_backend_address_pool" "openremote-lb-pool" {
  count           = var.enable_private_vm_setup ? 1 : 0
  name            = "openremote-lb-pool"
  loadbalancer_id = azurerm_lb.load_balancer[count.index].id
}

resource "azurerm_lb_rule" "https_rule" {
  count                          = var.enable_private_vm_setup ? 1 : 0
  name                           = "https-rule"
  loadbalancer_id                = azurerm_lb.load_balancer[count.index].id
  frontend_ip_configuration_name = "frontend"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.openremote-lb-pool[count.index].id]
  probe_id                       = azurerm_lb_probe.https_probe[count.index].id
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "http_rule" {
  count                          = var.enable_private_vm_setup ? 1 : 0
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.load_balancer[count.index].id
  frontend_ip_configuration_name = "frontend"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.openremote-lb-pool[count.index].id]
  probe_id                       = azurerm_lb_probe.http_probe[count.index].id
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "mqtt_rule" {
  count                          = var.enable_private_vm_setup ? 1 : 0
  name                           = "mqtt-rule"
  loadbalancer_id                = azurerm_lb.load_balancer[count.index].id
  frontend_ip_configuration_name = "frontend"
  protocol                       = "Tcp"
  frontend_port                  = 8883
  backend_port                   = 8883
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.openremote-lb-pool[count.index].id]
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "smtp_rule" {
  count                          = var.enable_private_vm_setup ? 1 : 0
  name                           = "smtp-rule"
  loadbalancer_id                = azurerm_lb.load_balancer[count.index].id
  frontend_ip_configuration_name = "frontend"
  protocol                       = "Tcp"
  frontend_port                  = 25
  backend_port                   = 25
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.openremote-lb-pool[count.index].id]
  disable_outbound_snat          = true
}

resource "azurerm_lb_probe" "http_probe" {
  count           = var.enable_private_vm_setup ? 1 : 0
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.load_balancer[count.index].id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_probe" "https_probe" {
  count           = var.enable_private_vm_setup ? 1 : 0
  name            = "https-probe"
  loadbalancer_id = azurerm_lb.load_balancer[count.index].id
  protocol        = "Tcp"
  port            = 443
}

output "lb-ip" {
  value = var.enable_private_vm_setup ? azurerm_public_ip.openremote-lb-ip[0].ip_address : null
}