resource "azurerm_public_ip" "nat_gw_ip" {
  count               = var.enable_private_vm_setup ? 1 : 0
  name                = "nat-gw-ip"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  location            = azurerm_resource_group.openremote-rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_nat_gateway" "openremote_nat_gw" {
  count               = var.enable_private_vm_setup ? 1 : 0
  name                = "openremote-nat-gw"
  location            = azurerm_resource_group.openremote-rg.location
  resource_group_name = azurerm_resource_group.openremote-rg.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "name" {
  count                = var.enable_private_vm_setup ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.openremote_nat_gw[count.index].id
  public_ip_address_id = azurerm_public_ip.nat_gw_ip[count.index].id
}

resource "azurerm_subnet_nat_gateway_association" "openremote_subnet_nat_gw_assoc" {
  count          = var.enable_private_vm_setup ? 1 : 0
  subnet_id      = azurerm_subnet.openremote-subnet.id
  nat_gateway_id = azurerm_nat_gateway.openremote_nat_gw[count.index].id
}
