variable "name" {
  description = "Name of the virtual network"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,62}[a-zA-Z0-9]$", var.name))
    error_message = "VNet name must be 2-64 characters, start with a letter, end with alphanumeric, and contain only alphanumerics and hyphens."
  }
}

variable "location" {
  description = "Azure region for the virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network (list of CIDR blocks)"
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space CIDR block is required."
  }

  validation {
    condition     = alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "All address space entries must be valid CIDR blocks."
  }
}

variable "dns_servers" {
  description = "Custom DNS servers (empty list uses Azure-provided DNS)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for ip in var.dns_servers : can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", ip))])
    error_message = "All DNS servers must be valid IPv4 addresses."
  }
}

variable "ddos_protection_plan_id" {
  description = "ID of DDoS protection plan to associate (optional)"
  type        = string
  default     = null
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    address_prefix                                = string
    service_endpoints                             = optional(list(string), [])
    private_endpoint_network_policies             = optional(string, "Disabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    create_nsg                                    = optional(bool, true)
    nsg_rules = optional(list(object({
      name                         = string
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = optional(string, "*")
      destination_port_range       = optional(string)
      source_address_prefix        = optional(string)
      source_address_prefixes      = optional(list(string))
      destination_address_prefix   = optional(string)
      destination_address_prefixes = optional(list(string))
    })), [])
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.subnets : can(cidrhost(v.address_prefix, 0))])
    error_message = "All subnet address_prefix values must be valid CIDR blocks."
  }

  validation {
    condition = alltrue([
      for k, v in var.subnets : contains(["Enabled", "Disabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], v.private_endpoint_network_policies)
    ])
    error_message = "private_endpoint_network_policies must be one of: Enabled, Disabled, NetworkSecurityGroupEnabled, RouteTableEnabled."
  }
}

variable "private_dns_zone_links" {
  description = "Private DNS zones to link to this VNet"
  type = map(object({
    dns_zone_name           = string
    dns_zone_resource_group = string
    link_name               = optional(string)
    registration_enabled    = optional(bool, false)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
