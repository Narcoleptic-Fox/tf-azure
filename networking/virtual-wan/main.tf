/**
 * # Azure Virtual WAN Module
 *
 * Creates a Virtual WAN with hubs for multi-region connectivity.
 *
 * ## Features
 * - Virtual WAN and multiple hubs
 * - VNet connections
 * - VPN Gateway option
 * - ExpressRoute Gateway option
 * - Hub routing tables
 */

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Virtual WAN
# -----------------------------------------------------------------------------

resource "azurerm_virtual_wan" "this" {
  name                           = var.name
  resource_group_name            = var.resource_group_name
  location                       = var.location
  type                           = var.type
  disable_vpn_encryption         = var.disable_vpn_encryption
  allow_branch_to_branch_traffic = var.allow_branch_to_branch_traffic
  office365_local_breakout_category = var.office365_local_breakout_category

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Virtual Hubs
# -----------------------------------------------------------------------------

resource "azurerm_virtual_hub" "this" {
  for_each = var.hubs

  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  location               = each.value.location
  virtual_wan_id         = azurerm_virtual_wan.this.id
  address_prefix         = each.value.address_prefix
  hub_routing_preference = each.value.hub_routing_preference
  sku                    = each.value.sku

  tags = var.tags
}

# -----------------------------------------------------------------------------
# VNet Connections
# -----------------------------------------------------------------------------

resource "azurerm_virtual_hub_connection" "this" {
  for_each = var.vnet_connections

  name                      = each.key
  virtual_hub_id            = azurerm_virtual_hub.this[each.value.hub_key].id
  remote_virtual_network_id = each.value.vnet_id
  internet_security_enabled = each.value.internet_security_enabled

  dynamic "routing" {
    for_each = each.value.routing != null ? [each.value.routing] : []
    content {
      associated_route_table_id = routing.value.associated_route_table_id

      dynamic "propagated_route_table" {
        for_each = routing.value.propagated_route_tables != null ? [1] : []
        content {
          route_table_ids = routing.value.propagated_route_tables
          labels          = routing.value.labels
        }
      }

      dynamic "static_vnet_route" {
        for_each = routing.value.static_vnet_routes != null ? routing.value.static_vnet_routes : []
        content {
          name                = static_vnet_route.value.name
          address_prefixes    = static_vnet_route.value.address_prefixes
          next_hop_ip_address = static_vnet_route.value.next_hop_ip_address
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# VPN Gateway (Site-to-Site)
# -----------------------------------------------------------------------------

resource "azurerm_vpn_gateway" "this" {
  for_each = { for k, v in var.hubs : k => v if v.vpn_gateway != null }

  name                = each.value.vpn_gateway.name
  location            = each.value.location
  resource_group_name = var.resource_group_name
  virtual_hub_id      = azurerm_virtual_hub.this[each.key].id
  scale_unit          = each.value.vpn_gateway.scale_unit

  bgp_settings {
    asn         = each.value.vpn_gateway.bgp_asn
    peer_weight = each.value.vpn_gateway.bgp_peer_weight
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# ExpressRoute Gateway
# -----------------------------------------------------------------------------

resource "azurerm_express_route_gateway" "this" {
  for_each = { for k, v in var.hubs : k => v if v.expressroute_gateway != null }

  name                          = each.value.expressroute_gateway.name
  location                      = each.value.location
  resource_group_name           = var.resource_group_name
  virtual_hub_id                = azurerm_virtual_hub.this[each.key].id
  scale_units                   = each.value.expressroute_gateway.scale_units
  allow_non_virtual_wan_traffic = each.value.expressroute_gateway.allow_non_virtual_wan_traffic

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Point-to-Site VPN Gateway
# -----------------------------------------------------------------------------

resource "azurerm_point_to_site_vpn_gateway" "this" {
  for_each = { for k, v in var.hubs : k => v if v.p2s_gateway != null }

  name                        = each.value.p2s_gateway.name
  location                    = each.value.location
  resource_group_name         = var.resource_group_name
  virtual_hub_id              = azurerm_virtual_hub.this[each.key].id
  vpn_server_configuration_id = each.value.p2s_gateway.vpn_server_configuration_id
  scale_unit                  = each.value.p2s_gateway.scale_unit
  dns_servers                 = each.value.p2s_gateway.dns_servers

  connection_configuration {
    name = "default"

    vpn_client_address_pool {
      address_prefixes = each.value.p2s_gateway.client_address_pool
    }
  }

  tags = var.tags
}
