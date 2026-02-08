variable "name" {
  description = "Name of the Function App"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,58}[a-zA-Z0-9]$", var.name)) || can(regex("^[a-zA-Z][a-zA-Z0-9]?$", var.name))
    error_message = "Function App name must be 2-60 characters, start with letter, end with alphanumeric."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "os_type" {
  description = "Operating system type (Linux or Windows)"
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type must be Linux or Windows."
  }
}

# Service Plan
variable "create_service_plan" {
  description = "Create a new service plan"
  type        = bool
  default     = true
}

variable "service_plan_name" {
  description = "Name of the service plan (if creating)"
  type        = string
  default     = null
}

variable "service_plan_id" {
  description = "ID of existing service plan (if not creating)"
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU name for the service plan"
  type        = string
  default     = "Y1"  # Consumption

  validation {
    condition = contains([
      "Y1",     # Consumption
      "EP1", "EP2", "EP3",  # Elastic Premium
      "B1", "B2", "B3",     # Basic
      "S1", "S2", "S3",     # Standard
      "P1v2", "P2v2", "P3v2", "P1v3", "P2v3", "P3v3"  # Premium
    ], var.sku_name)
    error_message = "sku_name must be a valid App Service Plan SKU."
  }
}

variable "maximum_elastic_worker_count" {
  description = "Maximum number of elastic workers (Premium plans)"
  type        = number
  default     = 20
}

variable "zone_balancing_enabled" {
  description = "Enable zone balancing for the service plan"
  type        = bool
  default     = false
}

# Storage
variable "storage_account_name" {
  description = "Name of the storage account for function app"
  type        = string
}

variable "storage_account_access_key" {
  description = "Access key for the storage account"
  type        = string
  default     = null
  sensitive   = true
}

variable "storage_uses_managed_identity" {
  description = "Use managed identity for storage access"
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

variable "azure_client_id" {
  description = "Client ID for managed identity (for Key Vault references)"
  type        = string
  default     = null
}

variable "key_vault_reference_identity_id" {
  description = "Identity ID for Key Vault references"
  type        = string
  default     = null
}

# Site Config
variable "always_on" {
  description = "Keep the app always on"
  type        = bool
  default     = true
}

variable "http2_enabled" {
  description = "Enable HTTP/2"
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "minimum_tls_version must be 1.0, 1.1, or 1.2."
  }
}

variable "ftps_state" {
  description = "FTPS state"
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["AllAllowed", "FtpsOnly", "Disabled"], var.ftps_state)
    error_message = "ftps_state must be AllAllowed, FtpsOnly, or Disabled."
  }
}

variable "vnet_route_all_enabled" {
  description = "Route all outbound traffic through VNet"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = null
}

variable "health_check_eviction_time_in_min" {
  description = "Minutes before unhealthy instance is removed"
  type        = number
  default     = null
}

# Application Stack
variable "application_stack" {
  description = "Application stack configuration"
  type = object({
    dotnet_version              = optional(string)
    use_dotnet_isolated_runtime = optional(bool, true)
    java_version                = optional(string)
    node_version                = optional(string)
    python_version              = optional(string)
    powershell_core_version     = optional(string)
    use_custom_runtime          = optional(bool)
  })
  default = {
    dotnet_version              = "8.0"
    use_dotnet_isolated_runtime = true
  }
}

variable "functions_worker_runtime" {
  description = "Functions worker runtime"
  type        = string
  default     = "dotnet-isolated"

  validation {
    condition     = contains(["dotnet", "dotnet-isolated", "node", "python", "java", "powershell", "custom"], var.functions_worker_runtime)
    error_message = "functions_worker_runtime must be a valid runtime."
  }
}

variable "run_from_package" {
  description = "Run from deployment package"
  type        = bool
  default     = true
}

# CORS
variable "cors" {
  description = "CORS configuration"
  type = object({
    allowed_origins     = list(string)
    support_credentials = optional(bool, false)
  })
  default = null
}

# IP Restrictions
variable "ip_restrictions" {
  description = "IP restrictions for the function app"
  type = list(object({
    name                      = string
    action                    = optional(string, "Allow")
    ip_address                = optional(string)
    virtual_network_subnet_id = optional(string)
    service_tag               = optional(string)
    priority                  = optional(number, 100)
    headers                   = optional(map(list(string)))
  }))
  default = []
}

# App Settings
variable "app_settings" {
  description = "Additional app settings"
  type        = map(string)
  default     = {}
}

variable "sticky_app_setting_names" {
  description = "App settings that are slot-sticky"
  type        = list(string)
  default     = []
}

variable "sticky_connection_string_names" {
  description = "Connection strings that are slot-sticky"
  type        = list(string)
  default     = []
}

# Application Insights
variable "application_insights_key" {
  description = "Application Insights instrumentation key"
  type        = string
  default     = null
}

variable "application_insights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  default     = null
}

# Networking
variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet integration (outbound)"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint (inbound)"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for private endpoint"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
