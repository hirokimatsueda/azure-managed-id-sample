resource "azurerm_application_insights" "this" {
  name                = "appi-${var.app_name}-${var.environment}-${var.location}-${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"
}
