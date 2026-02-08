/**
 * # Azure Storage Account Module
 *
 * Creates a secure Azure Storage Account with optional private endpoints,
 * customer-managed keys, and lifecycle management.
 *
 * ## Features
 * - Blob, File, Queue, and Table services
 * - Private endpoints
 * - Customer-managed keys option
 * - Lifecycle management
 * - Immutable storage option
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
# Storage Account
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_kind             = var.account_kind
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  access_tier              = var.access_tier

  # Security settings
  min_tls_version                 = var.min_tls_version
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled
  default_to_oauth_authentication = var.default_to_oauth_authentication
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled

  # Advanced features
  is_hns_enabled           = var.is_hns_enabled
  sftp_enabled             = var.sftp_enabled
  nfsv3_enabled            = var.nfsv3_enabled
  large_file_share_enabled = var.large_file_share_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != "None" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # Customer Managed Keys
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }

  # Blob Properties
  dynamic "blob_properties" {
    for_each = var.blob_properties != null ? [var.blob_properties] : []
    content {
      versioning_enabled            = blob_properties.value.versioning_enabled
      change_feed_enabled           = blob_properties.value.change_feed_enabled
      change_feed_retention_in_days = blob_properties.value.change_feed_retention_in_days
      default_service_version       = blob_properties.value.default_service_version
      last_access_time_enabled      = blob_properties.value.last_access_time_enabled

      dynamic "cors_rule" {
        for_each = blob_properties.value.cors_rules != null ? blob_properties.value.cors_rules : []
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "delete_retention_policy" {
        for_each = blob_properties.value.delete_retention_days != null ? [1] : []
        content {
          days = blob_properties.value.delete_retention_days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = blob_properties.value.container_delete_retention_days != null ? [1] : []
        content {
          days = blob_properties.value.container_delete_retention_days
        }
      }

      dynamic "restore_policy" {
        for_each = blob_properties.value.restore_policy_days != null ? [1] : []
        content {
          days = blob_properties.value.restore_policy_days
        }
      }
    }
  }

  # Share Properties (Files)
  dynamic "share_properties" {
    for_each = var.share_properties != null ? [var.share_properties] : []
    content {
      dynamic "cors_rule" {
        for_each = share_properties.value.cors_rules != null ? share_properties.value.cors_rules : []
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "retention_policy" {
        for_each = share_properties.value.retention_days != null ? [1] : []
        content {
          days = share_properties.value.retention_days
        }
      }

      dynamic "smb" {
        for_each = share_properties.value.smb != null ? [share_properties.value.smb] : []
        content {
          versions                        = smb.value.versions
          authentication_types            = smb.value.authentication_types
          kerberos_ticket_encryption_type = smb.value.kerberos_ticket_encryption_type
          channel_encryption_type         = smb.value.channel_encryption_type
          multichannel_enabled            = smb.value.multichannel_enabled
        }
      }
    }
  }

  # Queue Properties
  dynamic "queue_properties" {
    for_each = var.queue_properties != null ? [var.queue_properties] : []
    content {
      dynamic "cors_rule" {
        for_each = queue_properties.value.cors_rules != null ? queue_properties.value.cors_rules : []
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "logging" {
        for_each = queue_properties.value.logging != null ? [queue_properties.value.logging] : []
        content {
          delete                = logging.value.delete
          read                  = logging.value.read
          write                 = logging.value.write
          version               = logging.value.version
          retention_policy_days = logging.value.retention_policy_days
        }
      }

      dynamic "minute_metrics" {
        for_each = queue_properties.value.minute_metrics != null ? [queue_properties.value.minute_metrics] : []
        content {
          enabled               = minute_metrics.value.enabled
          include_apis          = minute_metrics.value.include_apis
          version               = minute_metrics.value.version
          retention_policy_days = minute_metrics.value.retention_policy_days
        }
      }

      dynamic "hour_metrics" {
        for_each = queue_properties.value.hour_metrics != null ? [queue_properties.value.hour_metrics] : []
        content {
          enabled               = hour_metrics.value.enabled
          include_apis          = hour_metrics.value.include_apis
          version               = hour_metrics.value.version
          retention_policy_days = hour_metrics.value.retention_policy_days
        }
      }
    }
  }

  # Static Website
  dynamic "static_website" {
    for_each = var.static_website != null ? [var.static_website] : []
    content {
      index_document     = static_website.value.index_document
      error_404_document = static_website.value.error_404_document
    }
  }

  # Network Rules
  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
      bypass                     = network_rules.value.bypass

      dynamic "private_link_access" {
        for_each = network_rules.value.private_link_access != null ? network_rules.value.private_link_access : []
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = private_link_access.value.endpoint_tenant_id
        }
      }
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Containers
# -----------------------------------------------------------------------------

resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = each.value.access_type
  metadata              = each.value.metadata
}

# -----------------------------------------------------------------------------
# File Shares
# -----------------------------------------------------------------------------

resource "azurerm_storage_share" "this" {
  for_each = var.file_shares

  name               = each.key
  storage_account_id = azurerm_storage_account.this.id
  quota              = each.value.quota
  access_tier        = each.value.access_tier
  enabled_protocol   = each.value.enabled_protocol
  metadata           = each.value.metadata
}

# -----------------------------------------------------------------------------
# Queues
# -----------------------------------------------------------------------------

resource "azurerm_storage_queue" "this" {
  for_each = var.queues

  name                 = each.key
  storage_account_name = azurerm_storage_account.this.name
  metadata             = each.value.metadata
}

# -----------------------------------------------------------------------------
# Tables
# -----------------------------------------------------------------------------

resource "azurerm_storage_table" "this" {
  for_each = var.tables

  name                 = each.key
  storage_account_name = azurerm_storage_account.this.name
}

# -----------------------------------------------------------------------------
# Lifecycle Management
# -----------------------------------------------------------------------------

resource "azurerm_storage_management_policy" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      filters {
        prefix_match = rule.value.prefix_match
        blob_types   = rule.value.blob_types
      }

      actions {
        dynamic "base_blob" {
          for_each = rule.value.base_blob != null ? [rule.value.base_blob] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than    = base_blob.value.tier_to_cool_after_days
            tier_to_archive_after_days_since_modification_greater_than = base_blob.value.tier_to_archive_after_days
            delete_after_days_since_modification_greater_than          = base_blob.value.delete_after_days
          }
        }

        dynamic "snapshot" {
          for_each = rule.value.snapshot != null ? [rule.value.snapshot] : []
          content {
            delete_after_days_since_creation_greater_than = snapshot.value.delete_after_days
          }
        }

        dynamic "version" {
          for_each = rule.value.version != null ? [rule.value.version] : []
          content {
            delete_after_days_since_creation = version.value.delete_after_days
          }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Private Endpoints
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                = "pe-${var.name}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "psc-${var.name}-${each.key}"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = [each.key]
  }

  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [each.value.private_dns_zone_id]
    }
  }

  tags = var.tags
}
