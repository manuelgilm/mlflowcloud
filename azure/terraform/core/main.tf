data "azurerm_client_config" "current" {}

locals {
  tenant_id_effective = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    "environment" = "demo"
    "application" = "mlflow"
    "managed_by"  = "terraform"
  }
}


resource "azurerm_container_registry" "acr" {
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
  resource_group_name           = azurerm_resource_group.rg.name
  retention_policy_in_days      = 0
  sku                           = "Basic"
  tags = {
    "environment" = "demo"
    "application" = "mlflow"
  }
  trust_policy_enabled    = false
  zone_redundancy_enabled = false
}

# Send ACR auth/repo events and metrics to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "acr_diag" {
  name                       = "acr-to-loganalytics"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_container_app_environment" "container_app_env" {
  location                       = var.location
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.log_analytics.id
  name                           = var.azure_container_app_env_name
  resource_group_name            = azurerm_resource_group.rg.name
  infrastructure_subnet_id       = azurerm_subnet.container_apps_subnet.id
  internal_load_balancer_enabled = false # Set to false to allow public ingress for MLflow
  tags = {
    "environment" = "demo"
    "application" = "mlflow"
  }
  workload_profile {
    maximum_count         = 0
    minimum_count         = 0
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  allow_resource_only_permissions         = true
  cmk_for_query_forced                    = false
  daily_quota_gb                          = -1
  immediate_data_purge_on_30_days_enabled = true
  internet_ingestion_enabled              = true
  internet_query_enabled                  = true
  location                                = var.location
  name                                    = var.azure_analytics_ws_name
  resource_group_name                     = azurerm_resource_group.rg.name
  retention_in_days                       = 30
  sku                                     = "PerGB2018"
  tags = {
    "environment" = "demo"
    "application" = "mlflow"
  }
}

resource "azurerm_storage_account" "artifact_storage" {
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
  public_network_access_enabled     = false
  queue_encryption_key_type         = "Service"
  resource_group_name               = azurerm_resource_group.rg.name
  sftp_enabled                      = false
  shared_access_key_enabled         = true
  table_encryption_key_type         = "Service"
  tags = {
    "environment" = "demo"
    "application" = "mlflow"
  }
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


resource "azurerm_storage_container" "artifact_container" {
  container_access_type = "private"
  metadata              = {}
  name                  = var.azure_artifacts_container_name
  storage_account_id    = azurerm_storage_account.artifact_storage.id
}
# Private DNS Zone for Storage Account (Blob)
resource "azurerm_private_dns_zone" "storage_blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    "environment" = "dev"
  }
}

# Link Storage Blob DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_dns_link" {
  name                  = "storage-blob-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags = {
    "environment" = "dev"
  }
}

# Private Endpoint for Storage Account (Blob)
resource "azurerm_private_endpoint" "storage_blob_endpoint" {
  name                = "${var.azure_storage_account_name}-blob-endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.storage_subnet.id
  tags = {
    "environment" = "dev"
  }

  private_service_connection {
    name                           = "${var.azure_storage_account_name}-blob-connection"
    private_connection_resource_id = azurerm_storage_account.artifact_storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "storage-blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob_dns.id]
  }
}

# Azure Key Vault for storing secrets
resource "azurerm_key_vault" "kv" {
  name                            = var.azure_keyvault_name
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg.name
  tenant_id                       = var.tenant_id
  sku_name                        = "standard"
  soft_delete_retention_days      = 7
  purge_protection_enabled        = false
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true
  rbac_authorization_enabled      = false
  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow" # Allow for demo - GitHub Actions needs access from dynamic IPs
  }
  tags = {
    "environment" = "demo"
    "application" = "mlflow"
  }
}

# Grant the current caller rights to manage secrets in this vault
resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = local.tenant_id_effective
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]
}

