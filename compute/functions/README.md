# Azure Functions Module

Creates Azure Functions with Consumption or Premium plans, VNet integration, Application Insights, and Key Vault reference support.

## Features

- ⚡ Consumption or Premium plans
- 🌐 VNet integration for outbound traffic
- 🔐 Private endpoint for inbound traffic
- 📊 Application Insights integration
- 🔑 Key Vault references for secrets
- 🔒 Managed identity support

## Usage

### Basic Consumption Function

```hcl
module "function" {
  source = "github.com/Narcoleptic-Fox/tf-azure//compute/functions"

  name                = "func-api-prod-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"

  create_service_plan  = true
  service_plan_name    = "asp-func-prod-001"
  sku_name             = "Y1"  # Consumption

  storage_account_name       = azurerm_storage_account.func.name
  storage_account_access_key = azurerm_storage_account.func.primary_access_key

  identity_type = "SystemAssigned"

  application_stack = {
    dotnet_version              = "8.0"
    use_dotnet_isolated_runtime = true
  }

  application_insights_connection_string = azurerm_application_insights.main.connection_string

  tags = {
    environment = "production"
  }
}
```

### Premium Function with VNet Integration

```hcl
module "function" {
  source = "github.com/Narcoleptic-Fox/tf-azure//compute/functions"

  name                = "func-processor-prod-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"

  create_service_plan  = true
  service_plan_name    = "asp-func-prod-001"
  sku_name             = "EP1"  # Elastic Premium
  zone_balancing_enabled = true

  storage_account_name          = azurerm_storage_account.func.name
  storage_uses_managed_identity = true

  # User-assigned identity for Key Vault and Storage
  identity_type                   = "UserAssigned"
  identity_ids                    = [azurerm_user_assigned_identity.func.id]
  key_vault_reference_identity_id = azurerm_user_assigned_identity.func.id
  azure_client_id                 = azurerm_user_assigned_identity.func.client_id

  # VNet integration for outbound
  vnet_integration_subnet_id = module.vnet.subnet_ids["snet-functions"]
  vnet_route_all_enabled     = true

  # Private endpoint for inbound
  public_network_access_enabled = false
  private_endpoint_subnet_id    = module.vnet.subnet_ids["snet-private-endpoints"]
  private_dns_zone_id           = module.dns_sites.id

  application_stack = {
    dotnet_version              = "8.0"
    use_dotnet_isolated_runtime = true
  }

  functions_worker_runtime = "dotnet-isolated"

  application_insights_connection_string = azurerm_application_insights.main.connection_string

  app_settings = {
    "ServiceBusConnection__fullyQualifiedNamespace" = "${azurerm_servicebus_namespace.main.name}.servicebus.windows.net"
    "CosmosDbConnection__accountEndpoint"           = azurerm_cosmosdb_account.main.endpoint
  }

  health_check_path = "/api/health"

  tags = {
    environment = "production"
  }
}
```

### With IP Restrictions

```hcl
module "function" {
  source = "github.com/Narcoleptic-Fox/tf-azure//compute/functions"

  name                = "func-api-prod-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"
  # ... other settings ...

  ip_restrictions = [
    {
      name       = "AllowFrontDoor"
      action     = "Allow"
      service_tag = "AzureFrontDoor.Backend"
      priority   = 100
      headers = {
        "x-azure-fdid" = [var.front_door_id]
      }
    },
    {
      name       = "AllowAPIManagement"
      action     = "Allow"
      service_tag = "ApiManagement"
      priority   = 110
    },
    {
      name       = "DenyAll"
      action     = "Deny"
      ip_address = "0.0.0.0/0"
      priority   = 1000
    }
  ]

  tags = {
    environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Function App name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| os_type | Linux or Windows | `string` | `"Linux"` | no |
| sku_name | Service plan SKU | `string` | `"Y1"` | no |
| storage_account_name | Storage account name | `string` | n/a | yes |
| identity_type | Managed identity type | `string` | `"SystemAssigned"` | no |
| vnet_integration_subnet_id | VNet integration subnet | `string` | `null` | no |
| private_endpoint_subnet_id | Private endpoint subnet | `string` | `null` | no |
| application_stack | Runtime configuration | `object` | .NET 8 isolated | no |
| app_settings | Additional app settings | `map(string)` | `{}` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Function App ID |
| name | Function App name |
| default_hostname | Default hostname |
| outbound_ip_addresses | Outbound IP addresses |
| identity_principal_id | System identity principal ID |
| service_plan_id | Service plan ID |
| private_endpoint_ip | Private endpoint IP |

## Security Considerations

- **HTTPS Only**: Always enabled
- **TLS 1.2**: Minimum version enforced
- **FTPS Disabled**: FTP access disabled by default
- **Managed Identity**: Use for Azure service access
- **Key Vault References**: Use `@Microsoft.KeyVault(...)` syntax in app settings
- **VNet Integration**: Route all traffic through VNet for private access

## Plan Comparison

| SKU | Type | VNet Integration | Always On | Scale |
|-----|------|------------------|-----------|-------|
| Y1 | Consumption | ❌ | ❌ | Auto (0-200) |
| EP1-EP3 | Elastic Premium | ✅ | ✅ | Auto (1-20+) |
| B1-B3 | Basic | ❌ | ✅ | Manual |
| S1-S3 | Standard | ❌ | ✅ | Manual |
| P1v3-P3v3 | Premium | ✅ | ✅ | Manual/Auto |

## Key Vault References

Use Key Vault references in app settings:
```hcl
app_settings = {
  "MySecret" = "@Microsoft.KeyVault(SecretUri=https://myvault.vault.azure.net/secrets/MySecret/)"
}
```

Requires:
- User-assigned identity with Key Vault access
- `key_vault_reference_identity_id` set to identity ID

## Subnet Requirements

### VNet Integration Subnet
- Minimum size: /28 (16 addresses)
- Recommended: /26 for Premium plans
- Requires delegation: `Microsoft.Web/serverFarms`

### Private Endpoint Subnet  
- Use shared private endpoint subnet
- Enable private endpoint network policies
