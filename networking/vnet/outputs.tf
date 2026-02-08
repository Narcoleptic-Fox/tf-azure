output "id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.this.address_space
}

output "location" {
  description = "Location of the virtual network"
  value       = azurerm_virtual_network.this.location
}

output "resource_group_name" {
  description = "Resource group name of the virtual network"
  value       = azurerm_virtual_network.this.resource_group_name
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to their address prefixes"
  value       = { for k, v in azurerm_subnet.this : k => v.address_prefixes[0] }
}

output "nsg_ids" {
  description = "Map of subnet names to their NSG IDs"
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "dns_zone_link_ids" {
  description = "Map of private DNS zone link names to their IDs"
  value       = { for k, v in azurerm_private_dns_zone_virtual_network_link.this : k => v.id }
}
