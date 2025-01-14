locals {
  vm_custom_data = base64encode(templatefile("${path.module}/customdata.tpl", {
    public_ip_tf = var.enable_private_vm_setup ? azurerm_public_ip.openremote-lb-ip[0].ip_address : azurerm_public_ip.openremote-ip[0].ip_address
  }))
  admin_account_password = "OpenRemote123!"
}