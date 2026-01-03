variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
}

variable "acr_name" {
  description = "Name for the Azure Container Registry"
  type        = string
}
variable "azure_analytics_ws_name" {
  description = "Analytics Workspace for the Container APP"
  type        = string
}

variable "azure_container_app_env_name" {
  description = "Name for the Azure Container APP environment"
  type        = string
}

variable "azure_storage_account_name" {
  description = "Storage Account Name This will be used for the Artifact Store"
  type        = string
}

variable "azure_artifacts_container_name" {
  description = "Container needed for the artifact store"
  type        = string
}

variable "postgresql_admin_password" {
  description = "Admin Password for default user"
  type        = string
  sensitive   = true
}


variable "postgresql_admin_username" {
  description = "Default Admin Username"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "tenant_id"
  type        = string
}

variable "postgresql_flexible_server_name" {
  description = "Name for the Postgresql Flexible Server"
  type        = string
}