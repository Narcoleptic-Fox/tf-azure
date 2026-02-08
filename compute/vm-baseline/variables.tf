variable "name" {
  description = "Name of the virtual machine"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", var.name)) || can(regex("^[a-zA-Z]$", var.name))
    error_message = "VM name must be 1-64 characters, start with a letter, and contain only alphanumerics and hyphens."
  }
}

variable "location" {
  description = "Azure region for the VM"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "os_type" {
  description = "Operating system type (Linux or Windows)"
  type        = string

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type must be either Linux or Windows."
  }
}

variable "size" {
  description = "VM size (e.g., Standard_D4s_v5)"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "zone" {
  description = "Availability zone (1, 2, or 3)"
  type        = string
  default     = null

  validation {
    condition     = var.zone == null || contains(["1", "2", "3"], var.zone)
    error_message = "Zone must be 1, 2, or 3 if specified."
  }
}

variable "subnet_id" {
  description = "Subnet ID for the VM's network interface"
  type        = string
}

variable "private_ip_address" {
  description = "Static private IP address (optional)"
  type        = string
  default     = null
}

variable "enable_accelerated_networking" {
  description = "Enable accelerated networking"
  type        = bool
  default     = true
}

# Authentication
variable "admin_username" {
  description = "Administrator username"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Administrator password (Windows only)"
  type        = string
  default     = null
  sensitive   = true
}

variable "admin_ssh_key" {
  description = "SSH public key for Linux VMs"
  type        = string
  default     = null
}

# Security Settings
variable "encryption_at_host_enabled" {
  description = "Enable encryption at host (requires subscription feature)"
  type        = bool
  default     = true
}

variable "vtpm_enabled" {
  description = "Enable Virtual TPM"
  type        = bool
  default     = true
}

variable "secure_boot_enabled" {
  description = "Enable Secure Boot (requires compatible image)"
  type        = bool
  default     = true
}

variable "disk_encryption_set_id" {
  description = "Disk encryption set ID for customer-managed keys"
  type        = string
  default     = null
}

# Patching
variable "patch_mode" {
  description = "Linux patch mode (ImageDefault or AutomaticByPlatform)"
  type        = string
  default     = "AutomaticByPlatform"

  validation {
    condition     = contains(["ImageDefault", "AutomaticByPlatform"], var.patch_mode)
    error_message = "patch_mode must be ImageDefault or AutomaticByPlatform."
  }
}

variable "windows_patch_mode" {
  description = "Windows patch mode"
  type        = string
  default     = "AutomaticByPlatform"

  validation {
    condition     = contains(["Manual", "AutomaticByOS", "AutomaticByPlatform"], var.windows_patch_mode)
    error_message = "windows_patch_mode must be Manual, AutomaticByOS, or AutomaticByPlatform."
  }
}

variable "patch_assessment_mode" {
  description = "Patch assessment mode"
  type        = string
  default     = "AutomaticByPlatform"

  validation {
    condition     = contains(["ImageDefault", "AutomaticByPlatform"], var.patch_assessment_mode)
    error_message = "patch_assessment_mode must be ImageDefault or AutomaticByPlatform."
  }
}

variable "enable_automatic_updates" {
  description = "Enable automatic updates (Windows only)"
  type        = bool
  default     = true
}

variable "hotpatching_enabled" {
  description = "Enable hotpatching (Windows only, requires specific SKUs)"
  type        = bool
  default     = false
}

# Identity
variable "identity_type" {
  description = "Managed identity type (None, SystemAssigned, UserAssigned, or both)"
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["None", "SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "identity_type must be None, SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "List of user-assigned managed identity IDs"
  type        = list(string)
  default     = []
}

# OS Disk
variable "os_disk_type" {
  description = "OS disk storage type"
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "Premium_ZRS", "StandardSSD_ZRS"], var.os_disk_type)
    error_message = "os_disk_type must be a valid storage account type."
  }
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = null
}

variable "os_disk_caching" {
  description = "OS disk caching mode"
  type        = string
  default     = "ReadWrite"

  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.os_disk_caching)
    error_message = "os_disk_caching must be None, ReadOnly, or ReadWrite."
  }
}

variable "os_disk_write_accelerator" {
  description = "Enable write accelerator (Premium_LRS M-series only)"
  type        = bool
  default     = false
}

# Source Image
variable "source_image" {
  description = "Source image reference"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Data Disks
variable "data_disks" {
  description = "Map of data disk configurations"
  type = map(object({
    disk_size_gb         = number
    storage_account_type = optional(string, "Premium_LRS")
    lun                  = number
    caching              = optional(string, "ReadOnly")
  }))
  default = {}
}

# Boot Diagnostics
variable "boot_diagnostics_storage_uri" {
  description = "Storage account URI for boot diagnostics (null = managed)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
