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

variable "postgresql_admin_password" {
  description = "Admin Password for default user"
  type        = string
}


variable "postgresql_admin_username" {
  description = "Default Admin Username"
  type        = string
}

variable "tenant_id" {
  description = "tenant_id"
  type        = string
}