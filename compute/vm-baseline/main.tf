/**
 * # Azure VM Baseline Module
 *
 * Creates hardened virtual machines following security best practices.
 *
 * ## Features
 * - Managed identity (system or user-assigned)
 * - Disk encryption at host
 * - No public IP (use Bastion)
 * - Boot diagnostics
 * - Automatic OS updates option
 */

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Network Interface
# -----------------------------------------------------------------------------

resource "azurerm_network_interface" "this" {
  name                          = "nic-${var.name}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.enable_accelerated_networking

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address != null ? "Static" : "Dynamic"
    private_ip_address            = var.private_ip_address
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Linux Virtual Machine
# -----------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "this" {
  count = var.os_type == "Linux" ? 1 : 0

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.size
  admin_username      = var.admin_username
  zone                = var.zone

  network_interface_ids = [azurerm_network_interface.this.id]

  # Security settings
  encryption_at_host_enabled = var.encryption_at_host_enabled
  vtpm_enabled               = var.vtpm_enabled
  secure_boot_enabled        = var.secure_boot_enabled
  patch_mode                 = var.patch_mode
  patch_assessment_mode      = var.patch_assessment_mode

  # Disable password auth when SSH key provided
  disable_password_authentication = var.admin_ssh_key != null

  dynamic "admin_ssh_key" {
    for_each = var.admin_ssh_key != null ? [var.admin_ssh_key] : []
    content {
      username   = var.admin_username
      public_key = admin_ssh_key.value
    }
  }

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != "None" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # OS Disk
  os_disk {
    name                      = "osdisk-${var.name}"
    caching                   = var.os_disk_caching
    storage_account_type      = var.os_disk_type
    disk_size_gb              = var.os_disk_size_gb
    disk_encryption_set_id    = var.disk_encryption_set_id
    write_accelerator_enabled = var.os_disk_write_accelerator
  }

  # Source Image
  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }

  # Boot Diagnostics
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_uri != null ? [1] : [1]
    content {
      storage_account_uri = var.boot_diagnostics_storage_uri
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      admin_ssh_key,
    ]
  }
}

# -----------------------------------------------------------------------------
# Windows Virtual Machine
# -----------------------------------------------------------------------------

resource "azurerm_windows_virtual_machine" "this" {
  count = var.os_type == "Windows" ? 1 : 0

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  zone                = var.zone

  network_interface_ids = [azurerm_network_interface.this.id]

  # Security settings
  encryption_at_host_enabled = var.encryption_at_host_enabled
  vtpm_enabled               = var.vtpm_enabled
  secure_boot_enabled        = var.secure_boot_enabled
  patch_mode                 = var.windows_patch_mode
  patch_assessment_mode      = var.patch_assessment_mode
  enable_automatic_updates   = var.enable_automatic_updates
  hotpatching_enabled        = var.hotpatching_enabled

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != "None" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # OS Disk
  os_disk {
    name                      = "osdisk-${var.name}"
    caching                   = var.os_disk_caching
    storage_account_type      = var.os_disk_type
    disk_size_gb              = var.os_disk_size_gb
    disk_encryption_set_id    = var.disk_encryption_set_id
    write_accelerator_enabled = var.os_disk_write_accelerator
  }

  # Source Image
  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }

  # Boot Diagnostics
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_uri != null ? [1] : [1]
    content {
      storage_account_uri = var.boot_diagnostics_storage_uri
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Data Disks
# -----------------------------------------------------------------------------

resource "azurerm_managed_disk" "data" {
  for_each = var.data_disks

  name                   = "disk-${var.name}-${each.key}"
  location               = var.location
  resource_group_name    = var.resource_group_name
  storage_account_type   = each.value.storage_account_type
  create_option          = "Empty"
  disk_size_gb           = each.value.disk_size_gb
  disk_encryption_set_id = var.disk_encryption_set_id
  zone                   = var.zone

  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = var.data_disks

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = var.os_type == "Linux" ? azurerm_linux_virtual_machine.this[0].id : azurerm_windows_virtual_machine.this[0].id
  lun                = each.value.lun
  caching            = each.value.caching
}
