resource "azurerm_recovery_services_vault" "openremote-backup-vault" {
  name                = "openremote-backup-vault"
  location            = azurerm_resource_group.openremote-rg.location
  resource_group_name = azurerm_resource_group.openremote-rg.name
  sku                 = "Standard"

  soft_delete_enabled = true
}

resource "azurerm_backup_policy_vm" "daily-backup-policy" {
  name                = "daily-backup-policy"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  recovery_vault_name = azurerm_recovery_services_vault.openremote-backup-vault.name

  backup {
    frequency = "Daily"
    time      = "05:00"
  }

  retention_daily {
    count = 7
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 3
    weekdays = ["Sunday"]
    weeks    = ["First", "Last"]
  }
}

resource "azurerm_backup_protected_vm" "openremote-backup" {
  resource_group_name = azurerm_resource_group.openremote-rg.name
  recovery_vault_name = azurerm_recovery_services_vault.openremote-backup-vault.name
  source_vm_id        = azurerm_linux_virtual_machine.openremote-vm.id
  backup_policy_id    = azurerm_backup_policy_vm.daily-backup-policy.id
}