variable "name" {
  description = "Name of the Virtual WAN"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,62}[a-zA-Z0-9]$", var.name))
    error_message = "Virtual WAN name must be 2-64 characters, start with a letter, and contain only alphanumerics and hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the Virtual WAN resource"
  type        = string
}

variable "type" {
  description = "Type of Virtual WAN (Basic or Standard)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.type)
    error_message = "Type must be either Basic or Standard."
  }
}

variable "disable_vpn_encryption" {
  description = "Disable VPN encryption (not recommended)"
  type        = bool
  default     = false
}

variable "allow_branch_to_branch_traffic" {
  description = "Allow branch-to-branch traffic"
  type        = bool
  default     = true
}

variable "office365_local_breakout_category" {
  description = "Office 365 local breakout category"
  type        = string
  default     = "None"

  validation {
    condition     = contains(["None", "Optimize", "OptimizeAndAllow", "All"], var.office365_local_breakout_category)
    error_message = "Office365 local breakout category must be one of: None, Optimize, OptimizeAndAllow, All."
  }
}

variable "hubs" {
  description = "Map of Virtual Hub configurations"
  type = map(object({
    name                   = string
    location               = string
    address_prefix         = string
    hub_routing_preference = optional(string, "ExpressRoute")
    sku                    = optional(string, "Standard")

    vpn_gateway = optional(object({
      name            = string
      scale_unit      = optional(number, 1)
      bgp_asn         = optional(number, 65515)
      bgp_peer_weight = optional(number, 0)
    }))

    expressroute_gateway = optional(object({
      name                          = string
      scale_units                   = optional(number, 1)
      allow_non_virtual_wan_traffic = optional(bool, false)
    }))

    p2s_gateway = optional(object({
      name                          = string
      vpn_server_configuration_id   = string
      scale_unit                    = optional(number, 1)
      dns_servers                   = optional(list(string), [])
      client_address_pool           = list(string)
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.hubs : can(cidrhost(v.address_prefix, 0))])
    error_message = "All hub address_prefix values must be valid CIDR blocks."
  }

  validation {
    condition     = alltrue([for k, v in var.hubs : contains(["Basic", "Standard"], v.sku)])
    error_message = "Hub SKU must be either Basic or Standard."
  }
}

variable "vnet_connections" {
  description = "Map of VNet connections to hubs"
  type = map(object({
    hub_key                   = string
    vnet_id                   = string
    internet_security_enabled = optional(bool, true)

    routing = optional(object({
      associated_route_table_id = optional(string)
      propagated_route_tables   = optional(list(string))
      labels                    = optional(list(string))
      static_vnet_routes = optional(list(object({
        name                = string
        address_prefixes    = list(string)
        next_hop_ip_address = string
      })))
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
