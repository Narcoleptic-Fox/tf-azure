variable "name" {
  description = "Front Door profile name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "sku_name" {
  description = "SKU name (Standard_AzureFrontDoor or Premium_AzureFrontDoor)"
  type        = string
  default     = "Standard_AzureFrontDoor"

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "SKU must be Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "response_timeout_seconds" {
  description = "Response timeout in seconds (16-240)"
  type        = number
  default     = 60

  validation {
    condition     = var.response_timeout_seconds >= 16 && var.response_timeout_seconds <= 240
    error_message = "Response timeout must be between 16 and 240 seconds."
  }
}

# -----------------------------------------------------------------------------
# Origin Groups and Origins
# -----------------------------------------------------------------------------

variable "origin_groups" {
  description = "Origin groups with their origins"
  type = map(object({
    session_affinity_enabled      = optional(bool, false)
    restore_traffic_time_minutes  = optional(number, 10)

    health_probe = object({
      interval_seconds = optional(number, 100)
      path             = optional(string, "/")
      protocol         = optional(string, "Https")
      request_type     = optional(string, "HEAD")
    })

    load_balancing = optional(object({
      additional_latency_ms       = optional(number, 50)
      sample_size                 = optional(number, 4)
      successful_samples_required = optional(number, 3)
    }), {})

    origins = list(object({
      name                         = string
      enabled                      = optional(bool, true)
      host_name                    = string
      http_port                    = optional(number, 80)
      https_port                   = optional(number, 443)
      origin_host_header           = optional(string)
      priority                     = optional(number, 1)
      weight                       = optional(number, 1000)
      certificate_name_check_enabled = optional(bool, true)
      private_link = optional(object({
        request_message        = optional(string, "Front Door Private Link")
        target_type            = string
        location               = string
        private_link_target_id = string
      }))
    }))
  }))
}

# -----------------------------------------------------------------------------
# Endpoints
# -----------------------------------------------------------------------------

variable "endpoints" {
  description = "Front Door endpoints"
  type = map(object({
    enabled = optional(bool, true)
  }))
}

# -----------------------------------------------------------------------------
# Custom Domains
# -----------------------------------------------------------------------------

variable "custom_domains" {
  description = "Custom domains configuration"
  type = map(object({
    dns_zone_id              = optional(string)
    dns_zone_resource_group  = optional(string)
    certificate_type         = optional(string, "ManagedCertificate")
    minimum_tls_version      = optional(string, "TLS12")
    secret_id                = optional(string)
    endpoint_name            = optional(string)
    create_dns_record        = optional(bool, false)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Routes
# -----------------------------------------------------------------------------

variable "routes" {
  description = "Routes configuration"
  type = map(object({
    endpoint_name          = string
    origin_group_name      = string
    origin_names           = list(string)
    enabled                = optional(bool, true)
    forwarding_protocol    = optional(string, "HttpsOnly")
    patterns_to_match      = optional(list(string), ["/*"])
    custom_domain_names    = optional(list(string))
    link_to_default_domain = optional(bool, true)
    rule_set_names         = optional(list(string))

    cache = optional(object({
      query_string_caching_behavior = optional(string, "IgnoreQueryString")
      query_strings                 = optional(list(string))
      compression_enabled           = optional(bool, true)
      content_types_to_compress     = optional(list(string), [
        "application/javascript",
        "application/json",
        "application/xml",
        "text/css",
        "text/html",
        "text/javascript",
        "text/plain",
        "text/xml"
      ])
    }))
  }))
}

# -----------------------------------------------------------------------------
# Rule Sets
# -----------------------------------------------------------------------------

variable "rule_sets" {
  description = "Rule sets with rules"
  type = map(object({
    rules = list(object({
      name              = string
      order             = number
      behavior_on_match = optional(string, "Continue")

      conditions = optional(object({
        request_uri = optional(object({
          operator     = string
          match_values = list(string)
        }))
        request_header = optional(object({
          header_name  = string
          operator     = string
          match_values = list(string)
        }))
        host_name = optional(object({
          operator     = string
          match_values = list(string)
        }))
      }))

      actions = object({
        url_redirect = optional(object({
          redirect_type        = string
          redirect_protocol    = optional(string, "Https")
          destination_hostname = optional(string)
          destination_path     = optional(string)
          destination_fragment = optional(string)
          query_string         = optional(string)
        }))
        url_rewrite = optional(object({
          source_pattern          = string
          destination             = string
          preserve_unmatched_path = optional(bool, true)
        }))
        response_headers = optional(list(object({
          header_action = string
          header_name   = string
          value         = optional(string)
        })))
        request_headers = optional(list(object({
          header_action = string
          header_name   = string
          value         = optional(string)
        })))
      })
    }))
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# WAF
# -----------------------------------------------------------------------------

variable "waf_policy_id" {
  description = "WAF policy ID to associate"
  type        = string
  default     = null
}

variable "waf_domain_names" {
  description = "Domain names to associate with WAF (defaults to all endpoints)"
  type        = list(string)
  default     = null
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
