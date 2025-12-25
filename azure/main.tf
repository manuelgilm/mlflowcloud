resource "azurerm_resource_group" "res-0" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    "environment" = "dev"
  }
}
resource "azurerm_container_registry" "res-1" {
  admin_enabled                 = true
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = false
  encryption                    = []
  export_policy_enabled         = true
  location                      = var.location
  name                          = var.acr_name
  network_rule_bypass_option    = "AzureServices"
  network_rule_set              = []
  public_network_access_enabled = true
  quarantine_policy_enabled     = false
  resource_group_name           = azurerm_resource_group.res-0.name
  retention_policy_in_days      = 0
  sku                           = "Basic"
  tags                          = {}
  trust_policy_enabled          = false
  zone_redundancy_enabled       = false
}

resource "azurerm_container_app_environment" "res-2" {
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.res-4.id
  name                       = var.azure_container_app_env_name
  resource_group_name        = azurerm_resource_group.res-0.name
  tags                       = {}
  workload_profile {
    maximum_count         = 0
    minimum_count         = 0
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_container_app" "res-3" {
  container_app_environment_id = azurerm_container_app_environment.res-2.id
  name                         = var.azure_container_app_name
  resource_group_name          = azurerm_resource_group.res-0.name
  revision_mode                = "Single"
  tags                         = {}
  workload_profile_name        = "Consumption"
  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 5000
    transport                  = "auto"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    max_replicas = 10
    min_replicas = 0
    container {
      cpu    = 1
      image  = "placeholder"
      memory = "2Gi"
      name   = "mlflow"
      env {
        name  = "MLFLOW_HOST"
        value = "0.0.0.0"
      }
      env {
        name  = "MLFLOW_PORT"
        value = "5000"
      }
      env {
        name  = "MLFLOW_SERVER_ALLOWED_HOSTS"
        value = "*"
      }
    }


  }

}

resource "azurerm_log_analytics_workspace" "res-4" {
  allow_resource_only_permissions         = true
  cmk_for_query_forced                    = false
  daily_quota_gb                          = -1
  immediate_data_purge_on_30_days_enabled = true
  internet_ingestion_enabled              = true
  internet_query_enabled                  = true
  location                                = var.location
  name                                    = var.azure_analytics_ws_name
  resource_group_name                     = azurerm_resource_group.res-0.name
  retention_in_days                       = 30
  sku                                     = "PerGB2018"
  tags                                    = {}
}

resource "azurerm_storage_account" "res-5" {
  access_tier                       = "Hot"
  account_kind                      = "StorageV2"
  account_replication_type          = "LRS"
  account_tier                      = "Standard"
  allow_nested_items_to_be_public   = false
  cross_tenant_replication_enabled  = false
  default_to_oauth_authentication   = false
  dns_endpoint_type                 = "Standard"
  https_traffic_only_enabled        = true
  infrastructure_encryption_enabled = false
  is_hns_enabled                    = false
  large_file_share_enabled          = true
  local_user_enabled                = true
  location                          = var.location
  min_tls_version                   = "TLS1_2"
  name                              = var.azure_storage_account_name
  nfsv3_enabled                     = false
  public_network_access_enabled     = true
  queue_encryption_key_type         = "Service"
  resource_group_name               = azurerm_resource_group.res-0.name
  sftp_enabled                      = false
  shared_access_key_enabled         = true
  table_encryption_key_type         = "Service"
  tags                              = {}
  blob_properties {
    change_feed_enabled      = false
    last_access_time_enabled = false
    versioning_enabled       = false
    container_delete_retention_policy {
      days = 7
    }
    delete_retention_policy {
      days                     = 7
      permanent_delete_enabled = false
    }
  }
  share_properties {
    retention_policy {
      days = 7
    }
  }
}


resource "azurerm_storage_container" "res-6" {
  container_access_type = "private"
  metadata              = {}
  name                  = var.azure_artifacts_container_name
  storage_account_name  = azurerm_storage_account.res-5.name
}