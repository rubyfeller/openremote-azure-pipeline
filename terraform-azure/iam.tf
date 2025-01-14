data "azuread_domains" "default_domain" {
  only_default = true
}

resource "azuread_user" "admin_user" {
  count = var.enable_admin_account ? 1 : 0

  user_principal_name   = "admin@${data.azuread_domains.default_domain.domains[0].domain_name}"
  display_name          = "OpenRemote Admin"
  mail_nickname         = "admin"
  password              = local.admin_account_password
  force_password_change = true
}

resource "azurerm_role_assignment" "admin_user_assignment" {
  count = var.enable_admin_account ? 1 : 0

  scope                = azurerm_resource_group.openremote-rg.id
  role_definition_name = "Owner"
  principal_id         = azuread_user.admin_user[count.index].object_id
}

output "admin_credentials" {
  value = var.enable_admin_account ? {
    username = azuread_user.admin_user[0].user_principal_name
    password = local.admin_account_password
  } : null
}
