resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.app_name}-${var.environment}-${var.location}-${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
}
