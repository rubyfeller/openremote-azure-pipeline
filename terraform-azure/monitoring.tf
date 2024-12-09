resource "azurerm_monitor_action_group" "email_alert" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "email-alert-group"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  short_name          = "emailalert"

  email_receiver {
    name          = "sendtoadmin"
    email_address = var.alert_email_address
  }
}

resource "azurerm_monitor_metric_alert" "vm_cpu_alert" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "vm-high-cpu-alert"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  scopes              = [azurerm_linux_virtual_machine.openremote-vm.id]
  description         = "Alert when CPU usage is above 80%"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_alert[0].id
  }
}