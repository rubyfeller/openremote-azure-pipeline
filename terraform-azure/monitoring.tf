resource "azurerm_log_analytics_workspace" "openremote-law" {
  name                = "openremote-monitoring-workspace"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  location            = azurerm_resource_group.openremote-rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "openremote-dcr"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  location            = azurerm_resource_group.openremote-rg.location
  kind                = "Linux"

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.openremote-law.id
      name                  = "destination-log"
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf"]
    destinations = ["destination-log"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\LogicalDisk(*)\\% Free Space",
        "\\Memory(*)\\Available MBytes Memory"
      ]
      name = "perfCounterDataSource"
    }
  }

  depends_on = [azurerm_log_analytics_workspace.openremote-law, azurerm_linux_virtual_machine.openremote-vm]
}

resource "azurerm_monitor_data_collection_rule_association" "dcr_association" {
  name                    = "openremote-dcra"
  target_resource_id      = azurerm_linux_virtual_machine.openremote-vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
  description             = "Associates VM with Data Collection Rule"
}

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

resource "azurerm_monitor_scheduled_query_rules_alert" "vm_disk_space_alert" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "vm-low-disk-space-alert"
  location            = azurerm_resource_group.openremote-rg.location
  resource_group_name = azurerm_resource_group.openremote-rg.name

  action {
    action_group = [azurerm_monitor_action_group.email_alert[0].id]
  }

  data_source_id = azurerm_log_analytics_workspace.openremote-law.id
  description    = "Alert when disk free space is below 15%"
  enabled        = true

  query = <<-QUERY
    Perf
    | where ObjectName == "Logical Disk" and CounterName == "% Free Space"
    | summarize AggregatedValue = avg(CounterValue) by Computer, _ResourceId
    | where AggregatedValue < 15
  QUERY

  severity    = 2
  frequency   = 5
  time_window = 15

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  depends_on = [
    azurerm_log_analytics_workspace.openremote-law,
    azurerm_linux_virtual_machine.openremote-vm
  ]
}

resource "azurerm_monitor_metric_alert" "vm_cpu_alert" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "vm-high-cpu-alert"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  scopes              = [azurerm_linux_virtual_machine.openremote-vm.id]
  description         = "Alert when CPU usage is above 80%"
  frequency           = "PT5M"
  window_size         = "PT15M"
  severity            = 2
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

resource "azurerm_monitor_metric_alert" "vm_memory_alert" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "vm-high-memory-alert"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  scopes              = [azurerm_linux_virtual_machine.openremote-vm.id]
  description         = "Alert when available memory is below 20%"
  frequency           = "PT5M"
  window_size         = "PT15M"
  severity            = 2
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 20
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_alert[0].id
  }
}

resource "azurerm_monitor_metric_alert" "vm_network_in_alert" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "vm-high-network-in-alert"
  resource_group_name = azurerm_resource_group.openremote-rg.name
  scopes              = [azurerm_linux_virtual_machine.openremote-vm.id]
  description         = "Alert when network in traffic is high"
  frequency           = "PT5M"
  window_size         = "PT15M"
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
  frequency           = "PT5M"
  window_size         = "PT15M"
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