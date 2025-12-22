resource "az_rg" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    "environment" = "dev"
  }
}