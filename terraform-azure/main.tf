resource "azurerm_resource_group" "openremote-rg" {
  name     = "${var.customer_name}-rg"
  location = var.region
}

resource "azurerm_log_analytics_workspace" "openremote-law" {
  name                = "openremote-law"
  location            = azurerm_resource_group.openremote-rg.location
  resource_group_name = azurerm_resource_group.openremote-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_data_collection_endpoint" "openremote-dce" {
  name                          = "openremote-dce"
  resource_group_name           = azurerm_resource_group.openremote-rg.name
  location                      = azurerm_resource_group.openremote-rg.location
  kind                          = "Linux"
  public_network_access_enabled = true
  description                   = "monitor_data_collection_endpoint"
}

resource "azurerm_monitor_data_collection_rule" "openremote-dcr-vm-metrics" {
  name                        = "openremote-dcr-vm-metrics"
  resource_group_name         = azurerm_resource_group.openremote-rg.name
  location                    = azurerm_resource_group.openremote-rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.openremote-dce.id

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.openremote-law.id
      name                  = "vm-metrics-destination"
    }
  }

  data_flow {
    streams = ["Microsoft-Perf"]
    destinations = ["vm-metrics-destination"]
  }
  
  data_sources {
    performance_counter {
      name = "vm-metrics"
      streams = ["Microsoft-Perf"]
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\LogicalDisk(_Total)\\% Free Space",
        "\\LogicalDisk(_Total)\\Free Megabytes"
      ]
      sampling_frequency_in_seconds = 60
    }
  }
}

resource "azurerm_virtual_machine_extension" "azure_monitor" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.openremote-vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
}

resource "azurerm_monitor_data_collection_rule_association" "vm_metrics" {
  name                    = "vm-metrics-dcra"
  target_resource_id      = azurerm_linux_virtual_machine.openremote-vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.openremote-dcr-vm-metrics.id
}

resource "azurerm_virtual_network" "openremote-vn" {
  name                = "openremote-network"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  location            = azurerm_resource_group.openremote-rg.location
  address_space       = ["10.123.0.0/16"]
}

resource "azurerm_subnet" "openremote-subnet" {
  name                 = "openremote-subnet"
  resource_group_name  = azurerm_resource_group.openremote-rg.name
  virtual_network_name = azurerm_virtual_network.openremote-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "openremote-sg" {
  name                = "openremote-sg"
  location            = azurerm_resource_group.openremote-rg.location
  resource_group_name = azurerm_resource_group.openremote-rg.name
}

resource "azurerm_network_security_rule" "openremote-dev-rule" {
  depends_on = [
    azurerm_network_security_group.openremote-sg
  ]
  name                        = "openremote-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.ssh_source_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.openremote-rg.name
  network_security_group_name = azurerm_network_security_group.openremote-sg.name
}

resource "azurerm_network_security_rule" "openremote-http" {
  depends_on = [
    azurerm_network_security_group.openremote-sg
  ]
  name                        = "openremote-http"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.openremote-rg.name
  network_security_group_name = azurerm_network_security_group.openremote-sg.name
}

resource "azurerm_network_security_rule" "openremote-https" {
  depends_on = [
    azurerm_network_security_group.openremote-sg
  ]
  name                        = "openremote-https"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.openremote-rg.name
  network_security_group_name = azurerm_network_security_group.openremote-sg.name
}

resource "azurerm_subnet_network_security_group_association" "openremote-sga" {
  subnet_id                 = azurerm_subnet.openremote-subnet.id
  network_security_group_id = azurerm_network_security_group.openremote-sg.id
}

resource "azurerm_public_ip" "openremote-ip" {
  name                = "openremote-ip"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  location            = azurerm_resource_group.openremote-rg.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "openremote-nic" {
  name                = "openremote-nic"
  location            = azurerm_resource_group.openremote-rg.location
  resource_group_name = azurerm_resource_group.openremote-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.openremote-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.openremote-ip.id
  }
}

resource "azurerm_linux_virtual_machine" "openremote-vm" {
  name                = "openremote-vm"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  location            = azurerm_resource_group.openremote-rg.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.openremote-nic.id,
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

output "instance_details" {
  value = "${azurerm_linux_virtual_machine.openremote-vm.name}: ${azurerm_public_ip.openremote-ip.ip_address}"
}