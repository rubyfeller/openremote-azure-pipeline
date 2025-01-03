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

variable "alert_frequency" {
  description = "How often to check the alert conditions"
  default     = "PT5M" # 5 minutes
}

variable "alert_window_size" {
  description = "Time window for alert evaluation"
  default     = "PT15M" # 15 minutes
}

resource "azurerm_monitor_metric_alert" "vm_cpu_alert" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "vm-high-cpu-alert"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  scopes              = [azurerm_linux_virtual_machine.openremote-vm.id]
  description         = "Alert when CPU usage is above 80%"
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size
  auto_mitigate       = true

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

resource "azurerm_monitor_scheduled_query_rules_alert" "memory_alert" {
  name                = "vm-high-memory-alert"
  location            = azurerm_resource_group.openremote-rg.location
  resource_group_name = azurerm_resource_group.openremote-rg.name

  action {
    action_group = [azurerm_monitor_action_group.email_alert[0].id]
  }

  data_source_id = azurerm_log_analytics_workspace.openremote-law.id
  description = "Alert when available memory is below 20%"
  enabled     = true

  query = <<-QUERY
    Perf
    | where TimeGenerated >= ago(15m)
    | where Namespace == "Memory"
    | where Name == "AvailableMemory"
    | summarize AggregatedValue = avg(Val) by bin(TimeGenerated, 5m)
    | where AggregatedValue < 20
  QUERY

  severity    = 3
  frequency   = 5
  time_window = 15

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "disk_alert" {
  name                = "vm-low-disk-space-alert"
  location            = azurerm_resource_group.openremote-rg.location
  resource_group_name = azurerm_resource_group.openremote-rg.name

  action {
    action_group = [azurerm_monitor_action_group.email_alert[0].id]
  }

  data_source_id = azurerm_log_analytics_workspace.openremote-law.id
  description    = "Alert when disk free space is below 20%"
  enabled        = true

  query = <<-QUERY
    Perf
    | where TimeGenerated >= ago(15m)
    | where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
    | summarize AggregatedValue = avg(CounterValue) by bin(TimeGenerated, 5m)
    | where AggregatedValue < 20
  QUERY

  severity    = 2
  frequency   = 5
  time_window = 15

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}

resource "azurerm_monitor_metric_alert" "vm_network_in_alert" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "vm-high-network-in-alert"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  scopes              = [azurerm_linux_virtual_machine.openremote-vm.id]
  description         = "Alert when network in traffic is high"
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Network In Total"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 100000000
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_alert[0].id
  }
}

resource "azurerm_monitor_metric_alert" "vm_network_out_alert" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "vm-high-network-out-alert"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  scopes              = [azurerm_linux_virtual_machine.openremote-vm.id]
  description         = "Alert when network out traffic is high"
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Network Out Total"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 100000000
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_alert[0].id
  }
}