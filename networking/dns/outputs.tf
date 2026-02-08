output "id" {
  description = "ID of the private DNS zone"
  value       = azurerm_private_dns_zone.this.id
}

output "name" {
  description = "Name of the private DNS zone"
  value       = azurerm_private_dns_zone.this.name
}

output "resource_group_name" {
  description = "Resource group name of the DNS zone"
  value       = azurerm_private_dns_zone.this.resource_group_name
}

output "number_of_record_sets" {
  description = "Number of record sets in the zone"
  value       = azurerm_private_dns_zone.this.number_of_record_sets
}

output "max_number_of_record_sets" {
  description = "Maximum number of record sets in the zone"
  value       = azurerm_private_dns_zone.this.max_number_of_record_sets
}

output "max_number_of_virtual_network_links" {
  description = "Maximum number of VNet links for the zone"
  value       = azurerm_private_dns_zone.this.max_number_of_virtual_network_links
}

output "vnet_link_ids" {
  description = "Map of VNet link names to their IDs"
  value       = { for k, v in azurerm_private_dns_zone_virtual_network_link.this : k => v.id }
}

output "a_record_ids" {
  description = "Map of A record names to their IDs"
  value       = { for k, v in azurerm_private_dns_a_record.this : k => v.id }
}

output "a_record_fqdns" {
  description = "Map of A record names to their FQDNs"
  value       = { for k, v in azurerm_private_dns_a_record.this : k => v.fqdn }
}

output "cname_record_ids" {
  description = "Map of CNAME record names to their IDs"
  value       = { for k, v in azurerm_private_dns_cname_record.this : k => v.id }
}

output "cname_record_fqdns" {
  description = "Map of CNAME record names to their FQDNs"
  value       = { for k, v in azurerm_private_dns_cname_record.this : k => v.fqdn }
}

output "ptr_record_ids" {
  description = "Map of PTR record names to their IDs"
  value       = { for k, v in azurerm_private_dns_ptr_record.this : k => v.id }
}

output "srv_record_ids" {
  description = "Map of SRV record names to their IDs"
  value       = { for k, v in azurerm_private_dns_srv_record.this : k => v.id }
}

output "txt_record_ids" {
  description = "Map of TXT record names to their IDs"
  value       = { for k, v in azurerm_private_dns_txt_record.this : k => v.id }
}
