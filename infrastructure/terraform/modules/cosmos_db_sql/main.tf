data "azurerm_client_config" "current" {}

resource "random_uuid" "role_assignment_id_user" {
}

resource "random_uuid" "role_assignment_id_data_contributor" {
}

resource "azurerm_cosmosdb_account" "this" {
  name                = "cosmos-${var.app_name}-${var.environment}-${var.location}-${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"

  enable_automatic_failover = true

  identity {
    type = "SystemAssigned"
  }

  capabilities {
    name = "EnableServerless"
  }

  backup {
    type = "Continuous"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = "japaneast"
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_role_definition" "data_contributor" {
  name                = "datacontributorsqlroledef"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  type                = "CustomRole"
  assignable_scopes   = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.DocumentDB/databaseAccounts/${azurerm_cosmosdb_account.this.name}"]

  permissions {
    data_actions = [
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*"
    ]
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "user" {
  name                = random_uuid.role_assignment_id_user.result
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.data_contributor.id
  principal_id        = data.azurerm_client_config.current.object_id
  scope               = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.DocumentDB/databaseAccounts/${azurerm_cosmosdb_account.this.name}"
}

resource "azurerm_cosmosdb_sql_role_assignment" "data_contributor" {
  depends_on = [
    azurerm_cosmosdb_sql_role_assignment.user
  ]

  name                = random_uuid.role_assignment_id_data_contributor.result
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.data_contributor.id
  principal_id        = var.data_contributor_principal_id
  scope               = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.DocumentDB/databaseAccounts/${azurerm_cosmosdb_account.this.name}"
}

resource "azurerm_cosmosdb_sql_database" "this" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
}

resource "azurerm_cosmosdb_sql_container" "this" {
  name                = var.container_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_sql_database.this.name
  partition_key_path  = var.partition_key_path
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                           = "diag"
  target_resource_id             = azurerm_cosmosdb_account.this.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "AzureDiagnostics"

  log {
    category = "DataPlaneRequests"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "QueryRuntimeStatistics"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "PartitionKeyStatistics"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "PartitionKeyRUConsumption"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "ControlPlaneRequests"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "MongoRequests"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "CassandraRequests"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "GremlinRequests"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "TableApiRequests"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "Requests"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }
}
