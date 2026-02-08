output "id" {
  description = "ID of the Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.this[0].id : azurerm_windows_function_app.this[0].id
}

output "name" {
  description = "Name of the Function App"
  value       = var.name
}

output "default_hostname" {
  description = "Default hostname of the Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.this[0].default_hostname : azurerm_windows_function_app.this[0].default_hostname
}

output "outbound_ip_addresses" {
  description = "Comma-separated list of outbound IP addresses"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.this[0].outbound_ip_addresses : azurerm_windows_function_app.this[0].outbound_ip_addresses
}

output "possible_outbound_ip_addresses" {
  description = "Comma-separated list of possible outbound IP addresses"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.this[0].possible_outbound_ip_addresses : azurerm_windows_function_app.this[0].possible_outbound_ip_addresses
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value = var.identity_type != "None" ? (
    var.os_type == "Linux" ? try(azurerm_linux_function_app.this[0].identity[0].principal_id, null) : try(azurerm_windows_function_app.this[0].identity[0].principal_id, null)
  ) : null
}

output "identity_tenant_id" {
  description = "Tenant ID of the system-assigned managed identity"
  value = var.identity_type != "None" ? (
    var.os_type == "Linux" ? try(azurerm_linux_function_app.this[0].identity[0].tenant_id, null) : try(azurerm_windows_function_app.this[0].identity[0].tenant_id, null)
  ) : null
}

output "service_plan_id" {
  description = "ID of the service plan"
  value       = var.create_service_plan ? azurerm_service_plan.this[0].id : var.service_plan_id
}

output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = var.private_endpoint_subnet_id != null ? azurerm_private_endpoint.this[0].id : null
}

output "private_endpoint_ip" {
  description = "Private IP address of the private endpoint"
  value       = var.private_endpoint_subnet_id != null ? azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address : null
}
