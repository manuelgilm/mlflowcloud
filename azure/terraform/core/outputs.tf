output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = azurerm_resource_group.res-0.name
}
output "primary_connection_string" {
  description = "The primary connection string for the Storage account."
  value       = azurerm_storage_account.res-5.primary_connection_string
  sensitive   = true
}

# Output the primary access key (also marked sensitive)
output "primary_access_key" {
  description = "The primary access key for the Storage account."
  value       = azurerm_storage_account.res-5.primary_access_key
  sensitive   = true
}

output "artifact_root" {
  description = "Default artifact root"
  value       = "wasbs://${azurerm_storage_container.res-6.name}@${azurerm_storage_account.res-5.name}.blob.core.windows.net/mlflow-artifacts"
  sensitive   = false
}

output "acr_login_server" {
  value       = azurerm_container_registry.res-1.login_server
  description = "Login server of the Azure Container Registry"
}
output "acr_login_username" {
  value       = azurerm_container_registry.res-1.name
  description = "Name to use to log the server"
  sensitive   = true
}

output "acr_login_password" {
  value       = azurerm_container_registry.res-1.admin_password
  description = "Password used to log in"
  sensitive   = true
}

output "container_app_env_id" {
  value = azurerm_container_app_environment.res-2.id
}

output "acr_id" {
  value       = azurerm_container_registry.res-1.id
  description = "Resource ID of the Azure Container Registry"
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "Resource ID of the Virtual Network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Name of the Virtual Network"
}

output "container_apps_subnet_id" {
  value       = azurerm_subnet.container_apps_subnet.id
  description = "Resource ID of the Container Apps subnet"
}

output "postgresql_subnet_id" {
  value       = azurerm_subnet.postgresql_subnet.id
  description = "Resource ID of the PostgreSQL subnet"
}

output "storage_subnet_id" {
  value       = azurerm_subnet.storage_subnet.id
  description = "Resource ID of the Storage subnet"
}

output "postgresql_private_endpoint_ip" {
  value       = azurerm_private_endpoint.postgresql_endpoint.private_service_connection[0].private_ip_address
  description = "Private IP address of the PostgreSQL private endpoint"
}

output "storage_private_endpoint_ip" {
  value       = azurerm_private_endpoint.storage_blob_endpoint.private_service_connection[0].private_ip_address
  description = "Private IP address of the Storage Blob private endpoint"
}