variable "zone_name" {
  description = "Name of the private DNS zone"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$", var.zone_name))
    error_message = "Zone name must be a valid DNS zone name."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "soa_record" {
  description = "SOA record configuration"
  type = object({
    email        = string
    expire_time  = optional(number, 2419200)
    minimum_ttl  = optional(number, 10)
    refresh_time = optional(number, 3600)
    retry_time   = optional(number, 300)
    ttl          = optional(number, 3600)
  })
  default = null
}

variable "vnet_links" {
  description = "Map of VNet links to create"
  type = map(object({
    vnet_id              = string
    registration_enabled = optional(bool, false)
  }))
  default = {}
}

variable "a_records" {
  description = "Map of A records to create"
  type = map(object({
    ttl     = optional(number, 300)
    records = list(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.a_records : alltrue([
        for ip in v.records : can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", ip))
      ])
    ])
    error_message = "All A record values must be valid IPv4 addresses."
  }
}

variable "aaaa_records" {
  description = "Map of AAAA records to create"
  type = map(object({
    ttl     = optional(number, 300)
    records = list(string)
  }))
  default = {}
}

variable "cname_records" {
  description = "Map of CNAME records to create"
  type = map(object({
    ttl    = optional(number, 300)
    record = string
  }))
  default = {}
}

variable "mx_records" {
  description = "Map of MX records to create"
  type = map(object({
    ttl = optional(number, 300)
    records = list(object({
      preference = number
      exchange   = string
    }))
  }))
  default = {}
}

variable "ptr_records" {
  description = "Map of PTR records to create"
  type = map(object({
    ttl     = optional(number, 300)
    records = list(string)
  }))
  default = {}
}

variable "srv_records" {
  description = "Map of SRV records to create"
  type = map(object({
    ttl = optional(number, 300)
    records = list(object({
      priority = number
      weight   = number
      port     = number
      target   = string
    }))
  }))
  default = {}
}

variable "txt_records" {
  description = "Map of TXT records to create"
  type = map(object({
    ttl     = optional(number, 300)
    records = list(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.txt_records : alltrue([
        for txt in v.records : length(txt) <= 1024
      ])
    ])
    error_message = "TXT record values must be 1024 characters or less."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
