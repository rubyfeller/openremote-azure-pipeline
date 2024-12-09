resource "azurerm_subnet" "openremote-application-gateway-subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.openremote-rg.name
  virtual_network_name = azurerm_virtual_network.openremote-vn.name
  address_prefixes     = ["10.123.2.0/24"]
}

resource "azurerm_public_ip" "openremote-ip" {
  name                = "openremote-ip"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  location            = azurerm_resource_group.openremote-rg.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_application_gateway" "openremote-application-gateway" {
    name = "openremote-application-gateway"
    resource_group_name = azurerm_resource_group.openremote-rg.name
    location = azurerm_resource_group.openremote-rg.location

    sku {
        name     = "Standard_v2"
        tier     = "Standard_v2"
        capacity = 2
    }

    gateway_ip_configuration {
        name      = "application-gateway-IP-configuration"
        subnet_id = azurerm_subnet.openremote-application-gateway-subnet.id
    }

    frontend_ip_configuration {
        name = "application-gateway-frontend-IP"
        public_ip_address_id = azurerm_public_ip.openremote-ip.id
    }

    frontend_port {
        name = "port-80"
        port = 80
    }

    backend_address_pool {
        name = "application-gateway-backend-pool"
        ip_addresses = [ azurerm_network_interface.openremote-nic.private_ip_address ]
    }

    backend_http_settings {
        name                                = "application-gateway-backend-HTTP-settings"
        cookie_based_affinity               = "Disabled"
        port                                = 80
        protocol                            = "Http"
        request_timeout                     = 20
    }

    http_listener {
        name                                = "application-gateway-HTTP-listener"
        frontend_ip_configuration_name      = "application-gateway-frontend-IP"
        frontend_port_name                  = "port-80"
        protocol                            = "Http"
    }


    request_routing_rule {
        name                                = "application-gateway-HTTP-routing-rule"
        rule_type                           = "Basic"
        http_listener_name                  = "application-gateway-HTTP-listener"
        backend_address_pool_name           = "application-gateway-backend-pool"
        backend_http_settings_name          = "application-gateway-backend-HTTP-settings"
    }
}
