/**
 * # Azure Front Door Module
 *
 * Creates an Azure Front Door (Standard/Premium) with origins, routes, and WAF.
 *
 * Security features:
 * - HTTPS only (redirect HTTP)
 * - TLS 1.2 minimum
 * - WAF policy integration
 * - Private Link origins (Premium)
 * - Custom domains with managed certificates
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
# Front Door Profile
# -----------------------------------------------------------------------------

resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name

  response_timeout_seconds = var.response_timeout_seconds

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Origin Groups
# -----------------------------------------------------------------------------

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  for_each = var.origin_groups

  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  session_affinity_enabled = each.value.session_affinity_enabled

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = each.value.restore_traffic_time_minutes

  health_probe {
    interval_in_seconds = each.value.health_probe.interval_seconds
    path                = each.value.health_probe.path
    protocol            = each.value.health_probe.protocol
    request_type        = each.value.health_probe.request_type
  }

  load_balancing {
    additional_latency_in_milliseconds = each.value.load_balancing.additional_latency_ms
    sample_size                        = each.value.load_balancing.sample_size
    successful_samples_required        = each.value.load_balancing.successful_samples_required
  }
}

# -----------------------------------------------------------------------------
# Origins
# -----------------------------------------------------------------------------

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = local.origins_flat

  name                          = each.value.name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group].id

  enabled                        = each.value.enabled
  host_name                      = each.value.host_name
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = each.value.origin_host_header
  priority                       = each.value.priority
  weight                         = each.value.weight
  certificate_name_check_enabled = each.value.certificate_name_check_enabled

  # Private Link (Premium SKU only)
  dynamic "private_link" {
    for_each = each.value.private_link != null && var.sku_name == "Premium_AzureFrontDoor" ? [each.value.private_link] : []
    content {
      request_message        = private_link.value.request_message
      target_type            = private_link.value.target_type
      location               = private_link.value.location
      private_link_target_id = private_link.value.private_link_target_id
    }
  }
}

# -----------------------------------------------------------------------------
# Endpoints
# -----------------------------------------------------------------------------

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  for_each = var.endpoints

  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  enabled = each.value.enabled

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Custom Domains
# -----------------------------------------------------------------------------

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each = var.custom_domains

  name                     = replace(each.key, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  dns_zone_id              = each.value.dns_zone_id
  host_name                = each.key

  tls {
    certificate_type    = each.value.certificate_type
    minimum_tls_version = each.value.minimum_tls_version
    cdn_frontdoor_secret_id = each.value.certificate_type == "CustomerCertificate" ? each.value.secret_id : null
  }
}

# -----------------------------------------------------------------------------
# Routes
# -----------------------------------------------------------------------------

resource "azurerm_cdn_frontdoor_route" "this" {
  for_each = var.routes

  name                          = each.key
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this[each.value.endpoint_name].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_name].id
  cdn_frontdoor_origin_ids      = [for o in each.value.origin_names : azurerm_cdn_frontdoor_origin.this["${each.value.origin_group_name}-${o}"].id]

  enabled = each.value.enabled

  forwarding_protocol    = each.value.forwarding_protocol
  https_redirect_enabled = true  # Always redirect HTTP to HTTPS
  patterns_to_match      = each.value.patterns_to_match
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = each.value.custom_domain_names != null ? [
    for domain in each.value.custom_domain_names : azurerm_cdn_frontdoor_custom_domain.this[domain].id
  ] : null

  link_to_default_domain = each.value.link_to_default_domain

  dynamic "cache" {
    for_each = each.value.cache != null ? [each.value.cache] : []
    content {
      query_string_caching_behavior = cache.value.query_string_caching_behavior
      query_strings                 = cache.value.query_strings
      compression_enabled           = cache.value.compression_enabled
      content_types_to_compress     = cache.value.content_types_to_compress
    }
  }

  cdn_frontdoor_rule_set_ids = each.value.rule_set_names != null ? [
    for rs in each.value.rule_set_names : azurerm_cdn_frontdoor_rule_set.this[rs].id
  ] : null
}

# -----------------------------------------------------------------------------
# Rule Sets
# -----------------------------------------------------------------------------

resource "azurerm_cdn_frontdoor_rule_set" "this" {
  for_each = var.rule_sets

  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_rule" "this" {
  for_each = local.rules_flat

  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[each.value.rule_set_name].id
  order                     = each.value.order
  behavior_on_match         = each.value.behavior_on_match

  # Conditions
  dynamic "conditions" {
    for_each = each.value.conditions != null ? [each.value.conditions] : []
    content {
      dynamic "request_uri_condition" {
        for_each = conditions.value.request_uri != null ? [conditions.value.request_uri] : []
        content {
          operator     = request_uri_condition.value.operator
          match_values = request_uri_condition.value.match_values
        }
      }

      dynamic "request_header_condition" {
        for_each = conditions.value.request_header != null ? [conditions.value.request_header] : []
        content {
          header_name  = request_header_condition.value.header_name
          operator     = request_header_condition.value.operator
          match_values = request_header_condition.value.match_values
        }
      }

      dynamic "host_name_condition" {
        for_each = conditions.value.host_name != null ? [conditions.value.host_name] : []
        content {
          operator     = host_name_condition.value.operator
          match_values = host_name_condition.value.match_values
        }
      }
    }
  }

  # Actions
  actions {
    dynamic "url_redirect_action" {
      for_each = each.value.actions.url_redirect != null ? [each.value.actions.url_redirect] : []
      content {
        redirect_type        = url_redirect_action.value.redirect_type
        redirect_protocol    = url_redirect_action.value.redirect_protocol
        destination_hostname = url_redirect_action.value.destination_hostname
        destination_path     = url_redirect_action.value.destination_path
        destination_fragment = url_redirect_action.value.destination_fragment
        query_string         = url_redirect_action.value.query_string
      }
    }

    dynamic "url_rewrite_action" {
      for_each = each.value.actions.url_rewrite != null ? [each.value.actions.url_rewrite] : []
      content {
        source_pattern          = url_rewrite_action.value.source_pattern
        destination             = url_rewrite_action.value.destination
        preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
      }
    }

    dynamic "response_header_action" {
      for_each = each.value.actions.response_headers != null ? each.value.actions.response_headers : []
      content {
        header_action = response_header_action.value.header_action
        header_name   = response_header_action.value.header_name
        value         = response_header_action.value.value
      }
    }

    dynamic "request_header_action" {
      for_each = each.value.actions.request_headers != null ? each.value.actions.request_headers : []
      content {
        header_action = request_header_action.value.header_action
        header_name   = request_header_action.value.header_name
        value         = request_header_action.value.value
      }
    }
  }
}

# -----------------------------------------------------------------------------
# WAF Policy Association
# -----------------------------------------------------------------------------

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  count = var.waf_policy_id != null ? 1 : 0

  name                     = "${var.name}-security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = var.waf_policy_id

      association {
        patterns_to_match = ["/*"]

        dynamic "domain" {
          for_each = var.waf_domain_names != null ? var.waf_domain_names : keys(var.endpoints)
          content {
            cdn_frontdoor_domain_id = contains(keys(var.custom_domains), domain.value) ? azurerm_cdn_frontdoor_custom_domain.this[domain.value].id : azurerm_cdn_frontdoor_endpoint.this[domain.value].id
          }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# DNS Records for Custom Domains
# -----------------------------------------------------------------------------

resource "azurerm_dns_cname_record" "this" {
  for_each = { for k, v in var.custom_domains : k => v if v.create_dns_record && v.dns_zone_id != null }

  name                = split(".", each.key)[0]
  zone_name           = join(".", slice(split(".", each.key), 1, length(split(".", each.key))))
  resource_group_name = each.value.dns_zone_resource_group
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.this[each.value.endpoint_name].host_name

  depends_on = [azurerm_cdn_frontdoor_custom_domain.this]
}

resource "azurerm_dns_txt_record" "validation" {
  for_each = { for k, v in var.custom_domains : k => v if v.create_dns_record && v.dns_zone_id != null }

  name                = "_dnsauth.${split(".", each.key)[0]}"
  zone_name           = join(".", slice(split(".", each.key), 1, length(split(".", each.key))))
  resource_group_name = each.value.dns_zone_resource_group
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.this[each.key].validation_token
  }
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  # Flatten origins for resource creation
  origins_flat = {
    for item in flatten([
      for group_name, group in var.origin_groups : [
        for origin in group.origins : {
          key                          = "${group_name}-${origin.name}"
          origin_group                 = group_name
          name                         = origin.name
          enabled                      = origin.enabled
          host_name                    = origin.host_name
          http_port                    = origin.http_port
          https_port                   = origin.https_port
          origin_host_header           = origin.origin_host_header
          priority                     = origin.priority
          weight                       = origin.weight
          certificate_name_check_enabled = origin.certificate_name_check_enabled
          private_link                 = origin.private_link
        }
      ]
    ]) : item.key => item
  }

  # Flatten rules for resource creation
  rules_flat = {
    for item in flatten([
      for rs_name, rs in var.rule_sets : [
        for rule in rs.rules : {
          key               = "${rs_name}-${rule.name}"
          rule_set_name     = rs_name
          name              = rule.name
          order             = rule.order
          behavior_on_match = rule.behavior_on_match
          conditions        = rule.conditions
          actions           = rule.actions
        }
      ]
    ]) : item.key => item
  }
}
