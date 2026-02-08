output "id" {
  description = "ID of the Virtual WAN"
  value       = azurerm_virtual_wan.this.id
}

output "name" {
  description = "Name of the Virtual WAN"
  value       = azurerm_virtual_wan.this.name
}

output "hub_ids" {
  description = "Map of hub keys to their IDs"
  value       = { for k, v in azurerm_virtual_hub.this : k => v.id }
}

output "hub_default_route_table_ids" {
  description = "Map of hub keys to their default route table IDs"
  value       = { for k, v in azurerm_virtual_hub.this : k => v.default_route_table_id }
}

output "hub_virtual_router_asns" {
  description = "Map of hub keys to their virtual router ASNs"
  value       = { for k, v in azurerm_virtual_hub.this : k => v.virtual_router_asn }
}

output "hub_virtual_router_ips" {
  description = "Map of hub keys to their virtual router IPs"
  value       = { for k, v in azurerm_virtual_hub.this : k => v.virtual_router_ips }
}

output "vnet_connection_ids" {
  description = "Map of VNet connection names to their IDs"
  value       = { for k, v in azurerm_virtual_hub_connection.this : k => v.id }
}

output "vpn_gateway_ids" {
  description = "Map of hub keys to VPN Gateway IDs"
  value       = { for k, v in azurerm_vpn_gateway.this : k => v.id }
}

output "vpn_gateway_bgp_settings" {
  description = "Map of hub keys to VPN Gateway BGP settings"
  value = {
    for k, v in azurerm_vpn_gateway.this : k => {
      asn                 = v.bgp_settings[0].asn
      bgp_peering_address = v.bgp_settings[0].bgp_peering_address
      peer_weight         = v.bgp_settings[0].peer_weight
    }
  }
}

output "expressroute_gateway_ids" {
  description = "Map of hub keys to ExpressRoute Gateway IDs"
  value       = { for k, v in azurerm_express_route_gateway.this : k => v.id }
}

output "p2s_gateway_ids" {
  description = "Map of hub keys to Point-to-Site VPN Gateway IDs"
  value       = { for k, v in azurerm_point_to_site_vpn_gateway.this : k => v.id }
}
