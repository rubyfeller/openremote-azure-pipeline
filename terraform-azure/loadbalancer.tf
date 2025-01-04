resource "azurerm_public_ip" "openremote-lb-ip" {
  name                = "openremote-lb-ip"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  location            = azurerm_resource_group.openremote-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "load_balancer" {
  name                = "openremote-lb"
  location            = azurerm_resource_group.openremote-rg.location
  resource_group_name = azurerm_resource_group.openremote-rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.openremote-lb-ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "openremote-lb-pool" {
  name            = "openremote-lb-pool"
  loadbalancer_id = azurerm_lb.load_balancer.id
}

resource "azurerm_lb_rule" "https_rule" {
  name                           = "https-rule"
  loadbalancer_id                = azurerm_lb.load_balancer.id
  frontend_ip_configuration_name = "frontend"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.openremote-lb-pool.id]
  probe_id                       = azurerm_lb_probe.https_probe.id
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "http_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.load_balancer.id
  frontend_ip_configuration_name = "frontend"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.openremote-lb-pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "mqtt_rule" {
  name                           = "mqtt-rule"
  loadbalancer_id                = azurerm_lb.load_balancer.id
  frontend_ip_configuration_name = "frontend"
  protocol                       = "Tcp"
  frontend_port                  = 8883
  backend_port                   = 8883
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.openremote-lb-pool.id]
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "smtp_rule" {
  name                           = "smtp-rule"
  loadbalancer_id                = azurerm_lb.load_balancer.id
  frontend_ip_configuration_name = "frontend"
  protocol                       = "Tcp"
  frontend_port                  = 25
  backend_port                   = 25
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.openremote-lb-pool.id]
  disable_outbound_snat          = true
}

resource "azurerm_lb_probe" "http_probe" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.load_balancer.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

resource "azurerm_lb_probe" "https_probe" {
  name            = "https-probe"
  loadbalancer_id = azurerm_lb.load_balancer.id
  protocol        = "Https"
  port            = 443
  request_path    = "/"
}

