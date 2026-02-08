output "id" {
  description = "ID of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.id
}

output "name" {
  description = "Name of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.name
}

output "endpoint" {
  description = "Endpoint of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "read_endpoints" {
  description = "Read endpoints for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.read_endpoints
}

output "write_endpoints" {
  description = "Write endpoints for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.write_endpoints
}

# Keys (sensitive)
output "primary_key" {
  description = "Primary key for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.primary_key
  sensitive   = true
}

output "secondary_key" {
  description = "Secondary key for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.secondary_key
  sensitive   = true
}

output "primary_readonly_key" {
  description = "Primary read-only key"
  value       = azurerm_cosmosdb_account.this.primary_readonly_key
  sensitive   = true
}

output "secondary_readonly_key" {
  description = "Secondary read-only key"
  value       = azurerm_cosmosdb_account.this.secondary_readonly_key
  sensitive   = true
}

# Connection Strings (sensitive)
output "primary_sql_connection_string" {
  description = "Primary SQL connection string"
  value       = azurerm_cosmosdb_account.this.primary_sql_connection_string
  sensitive   = true
}

output "secondary_sql_connection_string" {
  description = "Secondary SQL connection string"
  value       = azurerm_cosmosdb_account.this.secondary_sql_connection_string
  sensitive   = true
}

# Identity
output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value       = var.identity_type != "None" ? try(azurerm_cosmosdb_account.this.identity[0].principal_id, null) : null
}

output "identity_tenant_id" {
  description = "Tenant ID of the system-assigned managed identity"
  value       = var.identity_type != "None" ? try(azurerm_cosmosdb_account.this.identity[0].tenant_id, null) : null
}

# SQL Database IDs
output "sql_database_ids" {
  description = "Map of SQL database names to their IDs"
  value       = { for k, v in azurerm_cosmosdb_sql_database.this : k => v.id }
}

# SQL Container IDs
output "sql_container_ids" {
  description = "Map of SQL container keys to their IDs"
  value       = { for k, v in azurerm_cosmosdb_sql_container.this : k => v.id }
}

# Private Endpoint
output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = var.private_endpoint != null ? azurerm_private_endpoint.this[0].id : null
}

output "private_endpoint_ip" {
  description = "Private IP of the private endpoint"
  value       = var.private_endpoint != null ? azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address : null
}
