output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Name of the Virtual Network"
}
