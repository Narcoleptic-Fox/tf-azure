variable "name" {
  description = "Name of the Cosmos DB account"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,42}[a-z0-9]$", var.name))
    error_message = "Cosmos DB name must be 3-44 lowercase letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the primary location"
  type        = string
}

variable "kind" {
  description = "API kind (GlobalDocumentDB, MongoDB, Parse)"
  type        = string
  default     = "GlobalDocumentDB"

  validation {
    condition     = contains(["GlobalDocumentDB", "MongoDB", "Parse"], var.kind)
    error_message = "kind must be GlobalDocumentDB, MongoDB, or Parse."
  }
}

# Security Settings
variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "is_virtual_network_filter_enabled" {
  description = "Enable virtual network filter"
  type        = bool
  default     = true
}

variable "local_authentication_disabled" {
  description = "Disable local (key-based) authentication"
  type        = bool
  default     = true
}

variable "access_key_metadata_writes_enabled" {
  description = "Allow key-based metadata write operations"
  type        = bool
  default     = false
}

variable "network_acl_bypass_for_azure_services" {
  description = "Allow Azure services to bypass ACL"
  type        = bool
  default     = true
}

variable "network_acl_bypass_ids" {
  description = "Resource IDs that can bypass network ACL"
  type        = list(string)
  default     = []
}

variable "ip_range_filter" {
  description = "IP ranges allowed (comma-separated CIDRs or IPs)"
  type        = string
  default     = null
}

variable "minimal_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "Tls12"

  validation {
    condition     = contains(["Tls", "Tls11", "Tls12"], var.minimal_tls_version)
    error_message = "minimal_tls_version must be Tls, Tls11, or Tls12."
  }
}

# Features
variable "free_tier_enabled" {
  description = "Enable free tier (dev/test only)"
  type        = bool
  default     = false
}

variable "analytical_storage_enabled" {
  description = "Enable analytical storage (Synapse Link)"
  type        = bool
  default     = false
}

variable "analytical_storage_schema_type" {
  description = "Analytical storage schema type"
  type        = string
  default     = "WellDefined"

  validation {
    condition     = contains(["WellDefined", "FullFidelity"], var.analytical_storage_schema_type)
    error_message = "analytical_storage_schema_type must be WellDefined or FullFidelity."
  }
}

variable "multiple_write_locations_enabled" {
  description = "Enable multi-region writes"
  type        = bool
  default     = false
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover"
  type        = bool
  default     = true
}

variable "partition_merge_enabled" {
  description = "Enable partition merge"
  type        = bool
  default     = false
}

# Identity
variable "identity_type" {
  description = "Managed identity type"
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["None", "SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "identity_type must be None, SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "User-assigned identity IDs"
  type        = list(string)
  default     = []
}

# Consistency Policy
variable "consistency_level" {
  description = "Default consistency level"
  type        = string
  default     = "Session"

  validation {
    condition     = contains(["Eventual", "Session", "BoundedStaleness", "Strong", "ConsistentPrefix"], var.consistency_level)
    error_message = "consistency_level must be a valid consistency level."
  }
}

variable "max_interval_in_seconds" {
  description = "Max staleness interval (BoundedStaleness only)"
  type        = number
  default     = 5

  validation {
    condition     = var.max_interval_in_seconds >= 5 && var.max_interval_in_seconds <= 86400
    error_message = "max_interval_in_seconds must be between 5 and 86400."
  }
}

variable "max_staleness_prefix" {
  description = "Max staleness prefix (BoundedStaleness only)"
  type        = number
  default     = 100

  validation {
    condition     = var.max_staleness_prefix >= 10 && var.max_staleness_prefix <= 2147483647
    error_message = "max_staleness_prefix must be between 10 and 2147483647."
  }
}

# Geo Locations
variable "geo_locations" {
  description = "Geo-replication locations"
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, true)
  }))

  validation {
    condition     = length(var.geo_locations) > 0
    error_message = "At least one geo_location is required."
  }

  validation {
    condition     = anytrue([for gl in var.geo_locations : gl.failover_priority == 0])
    error_message = "One geo_location must have failover_priority = 0 (primary)."
  }
}

# Capabilities
variable "capabilities" {
  description = "Capabilities to enable"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cap in var.capabilities : contains([
        "EnableServerless",
        "EnableAggregationPipeline",
        "EnableCassandra",
        "EnableGremlin",
        "EnableMongo",
        "EnableTable",
        "MongoDBv3.4",
        "mongoEnableDocLevelTTL",
        "DisableRateLimitingResponses",
        "AllowSelfServeUpgradeToMongo36"
      ], cap)
    ])
    error_message = "capabilities must be valid Cosmos DB capabilities."
  }
}

# Virtual Network Rules
variable "virtual_network_rules" {
  description = "Virtual network rules for firewall"
  type = list(object({
    subnet_id                            = string
    ignore_missing_vnet_service_endpoint = optional(bool, false)
  }))
  default = []
}

# Backup Policy
variable "backup_policy" {
  description = "Backup policy configuration"
  type = object({
    type                = optional(string, "Continuous")
    interval_in_minutes = optional(number, 240)
    retention_in_hours  = optional(number, 8)
    storage_redundancy  = optional(string, "Geo")
    tier                = optional(string, "Continuous30Days")
  })
  default = {
    type               = "Continuous"
    tier               = "Continuous30Days"
    storage_redundancy = "Geo"
  }

  validation {
    condition     = contains(["Continuous", "Periodic"], var.backup_policy.type)
    error_message = "backup_policy.type must be Continuous or Periodic."
  }
}

# CORS Rules
variable "cors_rules" {
  description = "CORS rules"
  type = list(object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = []
}

# Customer Managed Key
variable "customer_managed_key" {
  description = "Customer-managed key configuration"
  type = object({
    key_vault_key_id      = string
    default_identity_type = optional(string, "FirstPartyIdentity")
  })
  default = null
}

# SQL Databases and Containers
variable "sql_databases" {
  description = "SQL databases and containers to create"
  type = map(object({
    throughput               = optional(number)
    autoscale_max_throughput = optional(number)
    containers = optional(map(object({
      partition_key_paths       = list(string)
      partition_key_version     = optional(number, 2)
      throughput                = optional(number)
      autoscale_max_throughput  = optional(number)
      default_ttl               = optional(number)
      analytical_storage_ttl    = optional(number)
      indexing_policy = optional(object({
        indexing_mode   = optional(string, "consistent")
        included_paths  = optional(list(string))
        excluded_paths  = optional(list(string))
        composite_indexes = optional(list(list(object({
          path  = string
          order = string
        }))))
        spatial_indexes = optional(list(string))
      }))
      unique_keys = optional(list(list(string)))
      conflict_resolution_policy = optional(object({
        mode                          = string
        conflict_resolution_path      = optional(string)
        conflict_resolution_procedure = optional(string)
      }))
    })), {})
  }))
  default = {}
}

# Private Endpoint
variable "private_endpoint" {
  description = "Private endpoint configuration"
  type = object({
    subnet_id           = string
    subresource_name    = optional(string, "Sql")
    private_dns_zone_id = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
