resource "azurerm_resource_group" "res-0" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    "environment" = "dev"
  }
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
