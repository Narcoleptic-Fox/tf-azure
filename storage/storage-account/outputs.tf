output "id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "primary_location" {
  description = "Primary location of the storage account"
  value       = azurerm_storage_account.this.primary_location
}

output "secondary_location" {
  description = "Secondary location (if GRS replication)"
  value       = azurerm_storage_account.this.secondary_location
}

# Blob Endpoints
output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_blob_host" {
  description = "Primary blob host"
  value       = azurerm_storage_account.this.primary_blob_host
}

output "secondary_blob_endpoint" {
  description = "Secondary blob endpoint"
  value       = azurerm_storage_account.this.secondary_blob_endpoint
}

# File Endpoints
output "primary_file_endpoint" {
  description = "Primary file endpoint"
  value       = azurerm_storage_account.this.primary_file_endpoint
}

output "primary_file_host" {
  description = "Primary file host"
  value       = azurerm_storage_account.this.primary_file_host
}

# Queue Endpoints
output "primary_queue_endpoint" {
  description = "Primary queue endpoint"
  value       = azurerm_storage_account.this.primary_queue_endpoint
}

output "primary_queue_host" {
  description = "Primary queue host"
  value       = azurerm_storage_account.this.primary_queue_host
}

# Table Endpoints
output "primary_table_endpoint" {
  description = "Primary table endpoint"
  value       = azurerm_storage_account.this.primary_table_endpoint
}

output "primary_table_host" {
  description = "Primary table host"
  value       = azurerm_storage_account.this.primary_table_host
}

# Web Endpoints
output "primary_web_endpoint" {
  description = "Primary web endpoint (static website)"
  value       = azurerm_storage_account.this.primary_web_endpoint
}

output "primary_web_host" {
  description = "Primary web host (static website)"
  value       = azurerm_storage_account.this.primary_web_host
}

# DFS Endpoints (Data Lake)
output "primary_dfs_endpoint" {
  description = "Primary DFS endpoint (Data Lake)"
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "primary_dfs_host" {
  description = "Primary DFS host (Data Lake)"
  value       = azurerm_storage_account.this.primary_dfs_host
}

# Access Keys (sensitive)
output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}

# Identity
output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value       = var.identity_type != "None" ? try(azurerm_storage_account.this.identity[0].principal_id, null) : null
}

output "identity_tenant_id" {
  description = "Tenant ID of the system-assigned managed identity"
  value       = var.identity_type != "None" ? try(azurerm_storage_account.this.identity[0].tenant_id, null) : null
}

# Container IDs
output "container_ids" {
  description = "Map of container names to their IDs"
  value       = { for k, v in azurerm_storage_container.this : k => v.id }
}

# File Share IDs
output "file_share_ids" {
  description = "Map of file share names to their IDs"
  value       = { for k, v in azurerm_storage_share.this : k => v.id }
}

# Queue IDs
output "queue_ids" {
  description = "Map of queue names to their IDs"
  value       = { for k, v in azurerm_storage_queue.this : k => v.id }
}

# Table IDs
output "table_ids" {
  description = "Map of table names to their IDs"
  value       = { for k, v in azurerm_storage_table.this : k => v.id }
}

# Private Endpoint IDs
output "private_endpoint_ids" {
  description = "Map of private endpoint subresources to their IDs"
  value       = { for k, v in azurerm_private_endpoint.this : k => v.id }
}

output "private_endpoint_ips" {
  description = "Map of private endpoint subresources to their private IPs"
  value       = { for k, v in azurerm_private_endpoint.this : k => v.private_service_connection[0].private_ip_address }
}
