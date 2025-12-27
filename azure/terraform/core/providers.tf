terraform {
  required_version = ">= 1.0.0"
  backend "azurerm" {
    resource_group_name  = "gilsamasstudyapitfstate"
    storage_account_name = "gilsamastfstatestg"
    container_name       = "mlflowcloudtfstate"
    key                  = "terraform.core.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.47.0"
    }
  }
}

provider "azurerm" {
  features {}
}