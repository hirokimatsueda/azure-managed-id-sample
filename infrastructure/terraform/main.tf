terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  app_name = random_string.app_name.id
  instance = format("%05d", random_integer.instance.result)

  cosmos_db_database_name  = "db"
  cosmos_db_container_name = "data"
  partition_key_path       = "/category"
}

resource "random_string" "app_name" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "random_integer" "instance" {
  min = 1
  max = 99999
}

module "mo_resource_group" {
  source = "./modules/resource_group"

  app_name    = local.app_name
  environment = var.environment
  location    = var.resource_group_location
  instance    = local.instance
}

module "mo_log_analytics_workspace" {
  source = "./modules/log_analytics_workspace"

  app_name            = local.app_name
  environment         = var.environment
  location            = var.resource_group_location
  instance            = local.instance
  resource_group_name = module.mo_resource_group.name
}

module "mo_application_insights" {
  source = "./modules/application_insights"

  app_name                   = local.app_name
  environment                = var.environment
  location                   = var.resource_group_location
  instance                   = local.instance
  resource_group_name        = module.mo_resource_group.name
  log_analytics_workspace_id = module.mo_log_analytics_workspace.id
}

module "mo_cosmos_db" {
  source = "./modules/cosmos_db_sql"

  app_name                   = local.app_name
  environment                = var.environment
  location                   = var.resource_group_location
  instance                   = local.instance
  resource_group_name        = module.mo_resource_group.name
  log_analytics_workspace_id = module.mo_log_analytics_workspace.id

  database_name      = local.cosmos_db_database_name
  container_name     = local.cosmos_db_container_name
  partition_key_path = local.partition_key_path

  data_contributor_principal_id = module.mo_functions.principal_id
}

module "mo_functions" {
  source = "./modules/functions_with_consumption_plan"

  app_name                               = local.app_name
  environment                            = var.environment
  location                               = var.resource_group_location
  instance                               = local.instance
  resource_group_name                    = module.mo_resource_group.name
  log_analytics_workspace_id             = module.mo_log_analytics_workspace.id
  application_insights_connection_string = module.mo_application_insights.connection_string
  application_insights_key               = module.mo_application_insights.instrumentation_key

  app_settings = {
    "COSMOS_ENDPOINT" = "https://cosmos-${local.app_name}-${var.environment}-${var.resource_group_location}-${local.instance}.documents.azure.com:443/"
  }
}
