output "profile_id" {
  description = "Front Door profile ID"
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "profile_name" {
  description = "Front Door profile name"
  value       = azurerm_cdn_frontdoor_profile.this.name
}

output "resource_guid" {
  description = "Front Door profile GUID"
  value       = azurerm_cdn_frontdoor_profile.this.resource_guid
}

output "sku_name" {
  description = "Front Door SKU"
  value       = azurerm_cdn_frontdoor_profile.this.sku_name
}

# Endpoints
output "endpoint_ids" {
  description = "Map of endpoint names to IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_endpoint.this : k => v.id }
}

output "endpoint_host_names" {
  description = "Map of endpoint names to host names"
  value       = { for k, v in azurerm_cdn_frontdoor_endpoint.this : k => v.host_name }
}

# Origin Groups
output "origin_group_ids" {
  description = "Map of origin group names to IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_origin_group.this : k => v.id }
}

# Origins
output "origin_ids" {
  description = "Map of origin keys to IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_origin.this : k => v.id }
}

# Custom Domains
output "custom_domain_ids" {
  description = "Map of custom domain names to IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.id }
}

output "custom_domain_validation_tokens" {
  description = "Map of custom domain names to validation tokens"
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.validation_token }
}

# Routes
output "route_ids" {
  description = "Map of route names to IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_route.this : k => v.id }
}

# Rule Sets
output "rule_set_ids" {
  description = "Map of rule set names to IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_rule_set.this : k => v.id }
}

# Security Policy
output "security_policy_id" {
  description = "Security policy ID (if WAF enabled)"
  value       = var.waf_policy_id != null ? azurerm_cdn_frontdoor_security_policy.this[0].id : null
}

# URLs
output "default_urls" {
  description = "Default endpoint URLs"
  value       = { for k, v in azurerm_cdn_frontdoor_endpoint.this : k => "https://${v.host_name}" }
}
