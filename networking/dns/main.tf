/**
 * # Azure Private DNS Module
 *
 * Creates private DNS zones with VNet links and DNS records.
 *
 * ## Features
 * - Private DNS zone creation
 * - VNet link management
 * - A, AAAA, CNAME, MX, PTR, SRV, TXT records
 * - Auto-registration option for VNet links
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
# Private DNS Zone
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "this" {
  name                = var.zone_name
  resource_group_name = var.resource_group_name

  dynamic "soa_record" {
    for_each = var.soa_record != null ? [var.soa_record] : []
    content {
      email        = soa_record.value.email
      expire_time  = soa_record.value.expire_time
      minimum_ttl  = soa_record.value.minimum_ttl
      refresh_time = soa_record.value.refresh_time
      retry_time   = soa_record.value.retry_time
      ttl          = soa_record.value.ttl
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# VNet Links
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.vnet_links

  name                  = each.key
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = each.value.registration_enabled

  tags = var.tags
}

# -----------------------------------------------------------------------------
# A Records
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_a_record" "this" {
  for_each = var.a_records

  name                = each.key
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = var.tags
}

# -----------------------------------------------------------------------------
# AAAA Records
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_aaaa_record" "this" {
  for_each = var.aaaa_records

  name                = each.key
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = var.tags
}

# -----------------------------------------------------------------------------
# CNAME Records
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_cname_record" "this" {
  for_each = var.cname_records

  name                = each.key
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record

  tags = var.tags
}

# -----------------------------------------------------------------------------
# MX Records
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_mx_record" "this" {
  for_each = var.mx_records

  name                = each.key
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      preference = record.value.preference
      exchange   = record.value.exchange
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# PTR Records
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_ptr_record" "this" {
  for_each = var.ptr_records

  name                = each.key
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = var.tags
}

# -----------------------------------------------------------------------------
# SRV Records
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_srv_record" "this" {
  for_each = var.srv_records

  name                = each.key
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      priority = record.value.priority
      weight   = record.value.weight
      port     = record.value.port
      target   = record.value.target
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# TXT Records
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_txt_record" "this" {
  for_each = var.txt_records

  name                = each.key
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      value = record.value
    }
  }

  tags = var.tags
}
