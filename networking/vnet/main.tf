/**
 * # Azure Virtual Network Module
 *
 * Creates a Virtual Network with multiple subnets, NSG associations,
 * service endpoints, and private DNS zone links.
 *
 * ## Features
 * - Multiple subnets with service endpoints
 * - NSG creation and association per subnet
 * - Subnet delegation for Azure services
 * - Private DNS zone links
 * - DDoS protection plan support
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
# Virtual Network
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                                          = each.key
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.this.name
  address_prefixes                              = [each.value.address_prefix]
  service_endpoints                             = each.value.service_endpoints
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Network Security Groups
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "this" {
  for_each = { for k, v in var.subnets : k => v if v.create_nsg }

  name                = "nsg-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = {
    for rule in local.nsg_rules_flat : "${rule.subnet_name}-${rule.name}" => rule
  }

  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.source_port_range
  destination_port_range       = each.value.destination_port_range
  source_address_prefix        = each.value.source_address_prefix
  source_address_prefixes      = each.value.source_address_prefixes
  destination_address_prefix   = each.value.destination_address_prefix
  destination_address_prefixes = each.value.destination_address_prefixes
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.this[each.value.subnet_name].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = { for k, v in var.subnets : k => v if v.create_nsg }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

# -----------------------------------------------------------------------------
# Private DNS Zone Links
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.private_dns_zone_links

  name                  = each.value.link_name != null ? each.value.link_name : "link-${var.name}"
  resource_group_name   = each.value.dns_zone_resource_group
  private_dns_zone_name = each.value.dns_zone_name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = each.value.registration_enabled

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  # Flatten NSG rules for easier iteration
  nsg_rules_flat = flatten([
    for subnet_name, subnet in var.subnets : [
      for rule in subnet.nsg_rules : merge(rule, { subnet_name = subnet_name })
    ] if subnet.create_nsg
  ])
}
