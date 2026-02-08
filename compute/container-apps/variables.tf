variable "name" {
  description = "Name of the Container App"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,30}[a-z0-9]$", var.name)) || can(regex("^[a-z]$", var.name))
    error_message = "Container App name must be lowercase, 1-32 characters, start with letter, end with alphanumeric."
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

# Environment settings
variable "create_environment" {
  description = "Create a new Container Apps Environment"
  type        = bool
  default     = false
}

variable "environment_name" {
  description = "Name of the Container Apps Environment (if creating)"
  type        = string
  default     = null
}

variable "container_app_environment_id" {
  description = "ID of existing Container Apps Environment (if not creating)"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for the environment"
  type        = string
  default     = null
}

variable "infrastructure_subnet_id" {
  description = "Subnet ID for VNet integration (minimum /23)"
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Enable internal load balancer (private ingress only)"
  type        = bool
  default     = true
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy"
  type        = bool
  default     = true
}

variable "infrastructure_resource_group_name" {
  description = "Resource group name for infrastructure resources"
  type        = string
  default     = null
}

variable "workload_profiles" {
  description = "Workload profiles for the environment"
  type = list(object({
    name                  = string
    workload_profile_type = string
    minimum_count         = optional(number)
    maximum_count         = optional(number)
  }))
  default = [{
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }]
}

variable "workload_profile_name" {
  description = "Workload profile to use for this app"
  type        = string
  default     = null
}

# App settings
variable "revision_mode" {
  description = "Revision mode (Single or Multiple)"
  type        = string
  default     = "Single"

  validation {
    condition     = contains(["Single", "Multiple"], var.revision_mode)
    error_message = "revision_mode must be Single or Multiple."
  }
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

# Registry
variable "registries" {
  description = "Container registries configuration"
  type = list(object({
    server               = string
    username             = optional(string)
    password_secret_name = optional(string)
    identity             = optional(string)
  }))
  default = []
}

# Secrets
variable "secrets" {
  description = "Secrets for the Container App"
  type = map(object({
    value               = optional(string)
    key_vault_secret_id = optional(string)
    identity            = optional(string)
  }))
  default   = {}
  sensitive = true
}

# Ingress
variable "ingress" {
  description = "Ingress configuration"
  type = object({
    external_enabled           = optional(bool, true)
    target_port                = number
    transport                  = optional(string, "http")
    allow_insecure_connections = optional(bool, false)
    exposed_port               = optional(number)
    traffic_weight = optional(list(object({
      percentage      = number
      latest_revision = optional(bool)
      revision_suffix = optional(string)
      label           = optional(string)
    })))
    ip_security_restrictions = optional(list(object({
      name             = string
      action           = string
      ip_address_range = string
      description      = optional(string)
    })))
  })
  default = null
}

# Dapr
variable "dapr" {
  description = "Dapr configuration"
  type = object({
    app_id       = string
    app_port     = optional(number)
    app_protocol = optional(string, "http")
  })
  default = null
}

# Template
variable "template" {
  description = "Container App template configuration"
  type = object({
    min_replicas    = optional(number, 0)
    max_replicas    = optional(number, 10)
    revision_suffix = optional(string)

    containers = list(object({
      name    = string
      image   = string
      cpu     = number
      memory  = string
      command = optional(list(string))
      args    = optional(list(string))

      env = optional(list(object({
        name        = string
        value       = optional(string)
        secret_name = optional(string)
      })))

      liveness_probe = optional(object({
        transport               = optional(string, "HTTP")
        port                    = number
        path                    = optional(string)
        initial_delay           = optional(number, 10)
        interval_seconds        = optional(number, 10)
        timeout                 = optional(number, 1)
        failure_count_threshold = optional(number, 3)
      }))

      readiness_probe = optional(object({
        transport               = optional(string, "HTTP")
        port                    = number
        path                    = optional(string)
        initial_delay           = optional(number, 0)
        interval_seconds        = optional(number, 10)
        timeout                 = optional(number, 1)
        failure_count_threshold = optional(number, 3)
      }))

      startup_probe = optional(object({
        transport               = optional(string, "HTTP")
        port                    = number
        path                    = optional(string)
        initial_delay           = optional(number, 0)
        interval_seconds        = optional(number, 10)
        timeout                 = optional(number, 1)
        failure_count_threshold = optional(number, 3)
      }))

      volume_mounts = optional(list(object({
        name = string
        path = string
      })))
    }))

    volumes = optional(list(object({
      name         = string
      storage_name = optional(string)
      storage_type = optional(string, "EmptyDir")
    })))

    http_scale_rules = optional(list(object({
      name                = string
      concurrent_requests = number
    })))

    custom_scale_rules = optional(list(object({
      name             = string
      custom_rule_type = string
      metadata         = map(string)
      authentication = optional(list(object({
        secret_name       = string
        trigger_parameter = string
      })))
    })))
  })
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
