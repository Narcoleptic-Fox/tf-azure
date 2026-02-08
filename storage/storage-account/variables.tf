variable "name" {
  description = "Name of the storage account (3-24 lowercase alphanumeric)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase letters and numbers only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "account_kind must be a valid storage account kind."
  }
}

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "GRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "account_replication_type must be a valid replication type."
  }
}

variable "access_tier" {
  description = "Default access tier for blobs"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "access_tier must be Hot or Cool."
  }
}

# Security Settings
variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "min_tls_version must be TLS1_0, TLS1_1, or TLS1_2."
  }
}

variable "allow_nested_items_to_be_public" {
  description = "Allow public access to blobs"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key (disable to force Entra ID auth)"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "default_to_oauth_authentication" {
  description = "Default to OAuth authentication in portal"
  type        = bool
  default     = true
}

variable "cross_tenant_replication_enabled" {
  description = "Allow cross-tenant replication"
  type        = bool
  default     = false
}

variable "infrastructure_encryption_enabled" {
  description = "Enable infrastructure encryption (double encryption)"
  type        = bool
  default     = false
}

# Advanced Features
variable "is_hns_enabled" {
  description = "Enable hierarchical namespace (Data Lake Gen2)"
  type        = bool
  default     = false
}

variable "sftp_enabled" {
  description = "Enable SFTP (requires HNS)"
  type        = bool
  default     = false
}

variable "nfsv3_enabled" {
  description = "Enable NFSv3 (requires HNS)"
  type        = bool
  default     = false
}

variable "large_file_share_enabled" {
  description = "Enable large file share support"
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

# Customer Managed Key
variable "customer_managed_key" {
  description = "Customer-managed key configuration"
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = string
  })
  default = null
}

# Blob Properties
variable "blob_properties" {
  description = "Blob service properties"
  type = object({
    versioning_enabled            = optional(bool, true)
    change_feed_enabled           = optional(bool, false)
    change_feed_retention_in_days = optional(number)
    default_service_version       = optional(string)
    last_access_time_enabled      = optional(bool, false)
    delete_retention_days         = optional(number, 30)
    container_delete_retention_days = optional(number, 30)
    restore_policy_days           = optional(number)
    cors_rules = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
  })
  default = {
    versioning_enabled              = true
    delete_retention_days           = 30
    container_delete_retention_days = 30
  }
}

# Share Properties
variable "share_properties" {
  description = "File share service properties"
  type = object({
    retention_days = optional(number)
    cors_rules = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    smb = optional(object({
      versions                        = optional(list(string))
      authentication_types            = optional(list(string))
      kerberos_ticket_encryption_type = optional(list(string))
      channel_encryption_type         = optional(list(string))
      multichannel_enabled            = optional(bool)
    }))
  })
  default = null
}

# Queue Properties
variable "queue_properties" {
  description = "Queue service properties"
  type = object({
    cors_rules = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    logging = optional(object({
      delete                = bool
      read                  = bool
      write                 = bool
      version               = string
      retention_policy_days = optional(number)
    }))
    minute_metrics = optional(object({
      enabled               = bool
      include_apis          = optional(bool)
      version               = string
      retention_policy_days = optional(number)
    }))
    hour_metrics = optional(object({
      enabled               = bool
      include_apis          = optional(bool)
      version               = string
      retention_policy_days = optional(number)
    }))
  })
  default = null
}

# Static Website
variable "static_website" {
  description = "Static website configuration"
  type = object({
    index_document     = optional(string, "index.html")
    error_404_document = optional(string, "404.html")
  })
  default = null
}

# Network Rules
variable "network_rules" {
  description = "Network access rules"
  type = object({
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
    bypass                     = optional(list(string), ["AzureServices"])
    private_link_access = optional(list(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string)
    })))
  })
  default = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# Containers
variable "containers" {
  description = "Blob containers to create"
  type = map(object({
    access_type = optional(string, "private")
    metadata    = optional(map(string))
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.containers : contains(["private", "blob", "container"], v.access_type)])
    error_message = "Container access_type must be private, blob, or container."
  }
}

# File Shares
variable "file_shares" {
  description = "File shares to create"
  type = map(object({
    quota            = number
    access_tier      = optional(string, "Hot")
    enabled_protocol = optional(string, "SMB")
    metadata         = optional(map(string))
  }))
  default = {}
}

# Queues
variable "queues" {
  description = "Queues to create"
  type = map(object({
    metadata = optional(map(string))
  }))
  default = {}
}

# Tables
variable "tables" {
  description = "Tables to create"
  type        = set(string)
  default     = []
}

# Lifecycle Rules
variable "lifecycle_rules" {
  description = "Lifecycle management rules"
  type = list(object({
    name         = string
    enabled      = optional(bool, true)
    prefix_match = optional(list(string))
    blob_types   = optional(list(string), ["blockBlob"])
    base_blob = optional(object({
      tier_to_cool_after_days    = optional(number)
      tier_to_archive_after_days = optional(number)
      delete_after_days          = optional(number)
    }))
    snapshot = optional(object({
      delete_after_days = number
    }))
    version = optional(object({
      delete_after_days = number
    }))
  }))
  default = []
}

# Private Endpoints
variable "private_endpoints" {
  description = "Private endpoints to create (key = subresource: blob, file, queue, table, web, dfs)"
  type = map(object({
    subnet_id           = string
    private_dns_zone_id = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.private_endpoints : contains(["blob", "blob_secondary", "file", "file_secondary", "queue", "queue_secondary", "table", "table_secondary", "web", "web_secondary", "dfs", "dfs_secondary"], k)])
    error_message = "Private endpoint key must be a valid storage subresource."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
