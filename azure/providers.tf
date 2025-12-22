terraform {
  required_version = ">= 1.0.0"
  backend "azurerm" {
    resource_group_name  = "gilsamasstudyapitfstate"
    storage_account_name = "gilsamastfstatestg"
    container_name       = "mlflowformldeploymenttfstate"
    key                  = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}