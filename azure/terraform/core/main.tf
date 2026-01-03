resource "azurerm_resource_group" "res-0" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    "environment" = "dev"
  }
}

# Virtual Network for secure internal communication
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.res-0.name
  tags = {
    "environment" = "dev"
  }
}

# Subnet for Container Apps Environment
resource "azurerm_subnet" "container_apps_subnet" {
  name                 = "container-apps-subnet"
  resource_group_name  = azurerm_resource_group.res-0.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/23"]

  # Required so Container Apps Environment can attach to the subnet
  delegation {
    name = "containerapps-delegation"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

# Subnet for PostgreSQL private endpoint
resource "azurerm_subnet" "postgresql_subnet" {
  name                 = "postgresql-subnet"
  resource_group_name  = azurerm_resource_group.res-0.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Subnet for Storage Account private endpoint
resource "azurerm_subnet" "storage_subnet" {
  name                 = "storage-subnet"
  resource_group_name  = azurerm_resource_group.res-0.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
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
  location                       = var.location
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.res-4.id
  name                           = var.azure_container_app_env_name
  resource_group_name            = azurerm_resource_group.res-0.name
  infrastructure_subnet_id       = azurerm_subnet.container_apps_subnet.id
  internal_load_balancer_enabled = false # Set to false to allow public ingress for MLflow
  tags                           = {}
  workload_profile {
    maximum_count         = 0
    minimum_count         = 0
    name                  = "Consumption"
    workload_profile_type = "Consumption"
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
  public_network_access_enabled     = false
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
  storage_account_id    = azurerm_storage_account.res-5.id
}

resource "azurerm_postgresql_flexible_server" "res-7" {
  administrator_login           = var.postgresql_admin_username
  administrator_password        = var.postgresql_admin_password
  auto_grow_enabled             = false
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  location                      = var.location
  name                          = var.postgresql_flexible_server_name
  public_network_access_enabled = false
  resource_group_name           = azurerm_resource_group.res-0.name
  sku_name                      = "B_Standard_B2s"
  storage_mb                    = 32768
  storage_tier                  = "P4"
  tags                          = {}
  version                       = "17"
  zone                          = "3"
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = var.tenant_id
  }
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.res-0.name
  tags = {
    "environment" = "dev"
  }
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql_dns_link" {
  name                  = "postgresql-dns-link"
  resource_group_name   = azurerm_resource_group.res-0.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags = {
    "environment" = "dev"
  }
}

# Private Endpoint for PostgreSQL
resource "azurerm_private_endpoint" "postgresql_endpoint" {
  name                = "${var.postgresql_flexible_server_name}-endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.res-0.name
  subnet_id           = azurerm_subnet.postgresql_subnet.id
  tags = {
    "environment" = "dev"
  }

  private_service_connection {
    name                           = "${var.postgresql_flexible_server_name}-connection"
    private_connection_resource_id = azurerm_postgresql_flexible_server.res-7.id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }

  private_dns_zone_group {
    name                 = "postgresql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.postgresql_dns.id]
  }
}

# Private DNS Zone for Storage Account (Blob)
resource "azurerm_private_dns_zone" "storage_blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.res-0.name
  tags = {
    "environment" = "dev"
  }
}

# Link Storage Blob DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_dns_link" {
  name                  = "storage-blob-dns-link"
  resource_group_name   = azurerm_resource_group.res-0.name
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
  resource_group_name = azurerm_resource_group.res-0.name
  subnet_id           = azurerm_subnet.storage_subnet.id
  tags = {
    "environment" = "dev"
  }

  private_service_connection {
    name                           = "${var.azure_storage_account_name}-blob-connection"
    private_connection_resource_id = azurerm_storage_account.res-5.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "storage-blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob_dns.id]
  }
}