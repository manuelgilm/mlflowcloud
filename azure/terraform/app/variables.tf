variable "image_name" {
  description = "Name of the docker image"
  type        = string
}

variable "azure_container_app_name" {
  description = "Name of the azure container app"
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

variable "postgresql_flexible_server_name" {
  description = "Name for the Postgresql Flexible Server"
  type = string
}