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

# Virtual Network for secure internal communication
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    "environment" = "demo"
    "application" = "mlflow"
  }
}

# Subnet for Container Apps Environment
resource "azurerm_subnet" "container_apps_subnet" {
  name                 = "container-apps-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
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
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Subnet for Storage Account private endpoint
resource "azurerm_subnet" "storage_subnet" {
  name                 = "storage-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Network Security Group for Container Apps
resource "azurerm_network_security_group" "container_apps_nsg" {
  name                = "${var.resource_group_name}-container-apps-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    "environment" = "dev"
  }

  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Container Apps Subnet
resource "azurerm_subnet_network_security_group_association" "container_apps_nsg_assoc" {
  subnet_id                 = azurerm_subnet.container_apps_subnet.id
  network_security_group_id = azurerm_network_security_group.container_apps_nsg.id
}

# Network Security Group for PostgreSQL
resource "azurerm_network_security_group" "postgresql_nsg" {
  name                = "${var.resource_group_name}-postgresql-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    "environment" = "dev"
  }

  security_rule {
    name                       = "AllowPostgreSQLFromContainerApps"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.0.0/23"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with PostgreSQL Subnet
resource "azurerm_subnet_network_security_group_association" "postgresql_nsg_assoc" {
  subnet_id                 = azurerm_subnet.postgresql_subnet.id
  network_security_group_id = azurerm_network_security_group.postgresql_nsg.id
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

# NOTE: Diagnostic settings already exist in Azure - managed outside Terraform
# Uncomment below if importing existing resources into state
# resource "azurerm_monitor_diagnostic_setting" "storage_diag" {
#   name                       = "storage-to-loganalytics"
#   target_resource_id         = azurerm_storage_account.artifact_storage.id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
#
#   enabled_metric {
#     category = "AllMetrics"
#   }
# }

resource "azurerm_storage_container" "artifact_container" {
  container_access_type = "private"
  metadata              = {}
  name                  = var.azure_artifacts_container_name
  storage_account_id    = azurerm_storage_account.artifact_storage.id
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  administrator_login           = var.postgresql_admin_username
  administrator_password        = var.postgresql_admin_password
  auto_grow_enabled             = true
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  location                      = var.location
  name                          = var.postgresql_flexible_server_name
  public_network_access_enabled = false
  resource_group_name           = azurerm_resource_group.rg.name
  sku_name                      = "B_Standard_B2s"
  storage_mb                    = 32768
  storage_tier                  = "P4"
  tags = {
    "environment" = "demo"
    "application" = "mlflow"
  }
  version = "17"
  zone    = "3"
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = var.tenant_id
  }
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    "environment" = "dev"
  }
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql_dns_link" {
  name                  = "postgresql-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
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
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.postgresql_subnet.id
  tags = {
    "environment" = "dev"
  }

  private_service_connection {
    name                           = "${var.postgresql_flexible_server_name}-connection"
    private_connection_resource_id = azurerm_postgresql_flexible_server.postgres.id
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
  rbac_authorization_enabled       = false
  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"  # Allow for demo - GitHub Actions needs access from dynamic IPs
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

# Store PostgreSQL password in Key Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  value        = var.postgresql_admin_password
  key_vault_id = azurerm_key_vault.kv.id
}

# Store PostgreSQL username in Key Vault
resource "azurerm_key_vault_secret" "postgres_username" {
  name         = "postgres-admin-username"
  value        = var.postgresql_admin_username
  key_vault_id = azurerm_key_vault.kv.id
}

# Store ACR password in Key Vault
resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-admin-password"
  value        = azurerm_container_registry.acr.admin_password
  key_vault_id = azurerm_key_vault.kv.id
}