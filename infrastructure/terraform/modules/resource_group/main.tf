resource "azurerm_resource_group" "this" {
  name     = "rg-${var.app_name}-${var.environment}-${var.location}-${var.instance}"
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}
