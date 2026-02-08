output "id" {
  description = "ID of the virtual machine"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.this[0].id : azurerm_windows_virtual_machine.this[0].id
}

output "name" {
  description = "Name of the virtual machine"
  value       = var.name
}

output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.this.private_ip_address
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.this.id
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value = var.identity_type != "None" ? (
    var.os_type == "Linux" ? try(azurerm_linux_virtual_machine.this[0].identity[0].principal_id, null) : try(azurerm_windows_virtual_machine.this[0].identity[0].principal_id, null)
  ) : null
}

output "identity_tenant_id" {
  description = "Tenant ID of the system-assigned managed identity"
  value = var.identity_type != "None" ? (
    var.os_type == "Linux" ? try(azurerm_linux_virtual_machine.this[0].identity[0].tenant_id, null) : try(azurerm_windows_virtual_machine.this[0].identity[0].tenant_id, null)
  ) : null
}

output "virtual_machine_id" {
  description = "Unique ID of the virtual machine"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.this[0].virtual_machine_id : azurerm_windows_virtual_machine.this[0].virtual_machine_id
}

output "data_disk_ids" {
  description = "Map of data disk names to their IDs"
  value       = { for k, v in azurerm_managed_disk.data : k => v.id }
}

output "os_disk_id" {
  description = "ID of the OS disk"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.this[0].os_disk[0].id : azurerm_windows_virtual_machine.this[0].os_disk[0].id
}
