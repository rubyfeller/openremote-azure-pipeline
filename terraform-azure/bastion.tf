resource "azurerm_subnet" "bastion_subnet" {
  count                = var.enable_private_vm_setup ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.openremote-rg.name
  virtual_network_name = azurerm_virtual_network.openremote-vn.name
  address_prefixes     = ["10.123.2.0/24"]
}


resource "azurerm_public_ip" "bastion_public_ip" {
  count               = var.enable_private_vm_setup ? 1 : 0
  name                = "openremote-bastion-ip"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  location            = azurerm_resource_group.openremote-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  count               = var.enable_private_vm_setup ? 1 : 0
  name                = "openremote-bastion"
  location            = azurerm_resource_group.openremote-rg.location
  resource_group_name = azurerm_resource_group.openremote-rg.name

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.bastion_subnet[count.index].id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip[count.index].id
  }
}
