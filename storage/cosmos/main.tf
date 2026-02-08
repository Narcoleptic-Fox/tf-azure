/**
 * # Azure Cosmos DB Module
 *
 * Creates a Cosmos DB account with configurable API, geo-replication,
 * private endpoint, and backup policies.
 *
 * ## Features
 * - SQL API (default), MongoDB, Cassandra, Gremlin, Table
 * - Multi-region writes option
 * - Private endpoint
 * - Backup policies (continuous or periodic)
 * - Managed identity authentication
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
# Cosmos DB Account
# -----------------------------------------------------------------------------

resource "azurerm_cosmosdb_account" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = var.kind

  # Security settings
  public_network_access_enabled         = var.public_network_access_enabled
  is_virtual_network_filter_enabled     = var.is_virtual_network_filter_enabled
  local_authentication_disabled         = var.local_authentication_disabled
  access_key_metadata_writes_enabled    = var.access_key_metadata_writes_enabled
  network_acl_bypass_for_azure_services = var.network_acl_bypass_for_azure_services
  network_acl_bypass_ids                = var.network_acl_bypass_ids
  ip_range_filter                       = var.ip_range_filter

  # Free tier (only for dev/test)
  free_tier_enabled = var.free_tier_enabled

  # Features
  analytical_storage_enabled        = var.analytical_storage_enabled
  multiple_write_locations_enabled  = var.multiple_write_locations_enabled
  automatic_failover_enabled        = var.automatic_failover_enabled
  partition_merge_enabled           = var.partition_merge_enabled
  minimal_tls_version               = var.minimal_tls_version

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != "None" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # Consistency Policy
  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.consistency_level == "BoundedStaleness" ? var.max_interval_in_seconds : null
    max_staleness_prefix    = var.consistency_level == "BoundedStaleness" ? var.max_staleness_prefix : null
  }

  # Geo Locations
  dynamic "geo_location" {
    for_each = var.geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }

  # Capabilities
  dynamic "capabilities" {
    for_each = var.capabilities
    content {
      name = capabilities.value
    }
  }

  # Virtual Network Rules
  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rules
    content {
      id                                   = virtual_network_rule.value.subnet_id
      ignore_missing_vnet_service_endpoint = virtual_network_rule.value.ignore_missing_vnet_service_endpoint
    }
  }

  # Backup Policy
  dynamic "backup" {
    for_each = var.backup_policy != null ? [var.backup_policy] : []
    content {
      type                = backup.value.type
      interval_in_minutes = backup.value.type == "Periodic" ? backup.value.interval_in_minutes : null
      retention_in_hours  = backup.value.type == "Periodic" ? backup.value.retention_in_hours : null
      storage_redundancy  = backup.value.storage_redundancy
      tier                = backup.value.type == "Continuous" ? backup.value.tier : null
    }
  }

  # CORS
  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers    = cors_rule.value.allowed_headers
      allowed_methods    = cors_rule.value.allowed_methods
      allowed_origins    = cors_rule.value.allowed_origins
      exposed_headers    = cors_rule.value.exposed_headers
      max_age_in_seconds = cors_rule.value.max_age_in_seconds
    }
  }

  # Analytical Storage (Synapse Link)
  dynamic "analytical_storage" {
    for_each = var.analytical_storage_enabled ? [1] : []
    content {
      schema_type = var.analytical_storage_schema_type
    }
  }

  # Customer Managed Key
  default_identity_type = var.customer_managed_key != null ? var.customer_managed_key.default_identity_type : null
  key_vault_key_id      = var.customer_managed_key != null ? var.customer_managed_key.key_vault_key_id : null

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to geo_location order
    ]
  }
}

# -----------------------------------------------------------------------------
# SQL Databases and Containers
# -----------------------------------------------------------------------------

resource "azurerm_cosmosdb_sql_database" "this" {
  for_each = var.sql_databases

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = each.value.throughput

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "this" {
  for_each = local.sql_containers_flat

  name                  = each.value.container_name
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.this[each.value.database_name].name
  partition_key_paths   = each.value.partition_key_paths
  partition_key_version = each.value.partition_key_version
  throughput            = each.value.throughput
  default_ttl           = each.value.default_ttl
  analytical_storage_ttl = each.value.analytical_storage_ttl

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }

  dynamic "indexing_policy" {
    for_each = each.value.indexing_policy != null ? [each.value.indexing_policy] : []
    content {
      indexing_mode = indexing_policy.value.indexing_mode

      dynamic "included_path" {
        for_each = indexing_policy.value.included_paths != null ? indexing_policy.value.included_paths : []
        content {
          path = included_path.value
        }
      }

      dynamic "excluded_path" {
        for_each = indexing_policy.value.excluded_paths != null ? indexing_policy.value.excluded_paths : []
        content {
          path = excluded_path.value
        }
      }

      dynamic "composite_index" {
        for_each = indexing_policy.value.composite_indexes != null ? indexing_policy.value.composite_indexes : []
        content {
          dynamic "index" {
            for_each = composite_index.value
            content {
              path  = index.value.path
              order = index.value.order
            }
          }
        }
      }

      dynamic "spatial_index" {
        for_each = indexing_policy.value.spatial_indexes != null ? indexing_policy.value.spatial_indexes : []
        content {
          path = spatial_index.value
        }
      }
    }
  }

  dynamic "unique_key" {
    for_each = each.value.unique_keys != null ? each.value.unique_keys : []
    content {
      paths = unique_key.value
    }
  }

  dynamic "conflict_resolution_policy" {
    for_each = each.value.conflict_resolution_policy != null ? [each.value.conflict_resolution_policy] : []
    content {
      mode                          = conflict_resolution_policy.value.mode
      conflict_resolution_path      = conflict_resolution_policy.value.conflict_resolution_path
      conflict_resolution_procedure = conflict_resolution_policy.value.conflict_resolution_procedure
    }
  }
}

# -----------------------------------------------------------------------------
# Private Endpoint
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint != null ? 1 : 0

  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    is_manual_connection           = false
    subresource_names              = [var.private_endpoint.subresource_name]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_endpoint.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_endpoint.private_dns_zone_id]
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  # Flatten SQL containers for iteration
  sql_containers_flat = {
    for item in flatten([
      for db_name, db in var.sql_databases : [
        for container_name, container in db.containers : {
          key                       = "${db_name}-${container_name}"
          database_name             = db_name
          container_name            = container_name
          partition_key_paths       = container.partition_key_paths
          partition_key_version     = container.partition_key_version
          throughput                = container.throughput
          autoscale_max_throughput  = container.autoscale_max_throughput
          default_ttl               = container.default_ttl
          analytical_storage_ttl    = container.analytical_storage_ttl
          indexing_policy           = container.indexing_policy
          unique_keys               = container.unique_keys
          conflict_resolution_policy = container.conflict_resolution_policy
        }
      ]
    ]) : item.key => item
  }
}
