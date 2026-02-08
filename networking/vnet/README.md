# Azure Virtual Network Module

Creates an Azure Virtual Network with multiple subnets, Network Security Groups, service endpoints, and private DNS zone links.

## Features

- 🌐 Virtual Network with configurable address space
- 📦 Multiple subnets with service endpoints
- 🔒 NSG creation and automatic subnet association
- 🎯 Subnet delegation for Azure services (Container Apps, Functions, etc.)
- 🔗 Private DNS zone links for private endpoint resolution
- 🛡️ DDoS protection plan support

## Usage

```hcl
module "vnet" {
  source = "github.com/Narcoleptic-Fox/tf-azure//networking/vnet"

  name                = "vnet-app-prod-eus2-001"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "snet-app" = {
      address_prefix    = "10.0.1.0/24"
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Sql"]
      nsg_rules = [
        {
          name                       = "AllowHTTPS"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }

    "snet-container-apps" = {
      address_prefix = "10.0.2.0/23"
      delegation = {
        name         = "container-apps"
        service_name = "Microsoft.App/environments"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }

    "snet-private-endpoints" = {
      address_prefix                    = "10.0.4.0/24"
      private_endpoint_network_policies = "Enabled"
      create_nsg                        = false
    }
  }

  private_dns_zone_links = {
    "keyvault" = {
      dns_zone_name           = "privatelink.vaultcore.azure.net"
      dns_zone_resource_group = "rg-dns-prod"
    }
    "storage" = {
      dns_zone_name           = "privatelink.blob.core.windows.net"
      dns_zone_resource_group = "rg-dns-prod"
    }
  }

  tags = {
    environment = "production"
    managed_by  = "terraform"
  }
}
```

## Integration with tf-security

```hcl
module "naming" {
  source = "github.com/Narcoleptic-Fox/tf-security//core/naming"

  project     = "navigator"
  environment = "prod"
  region      = "eastus2"
}

module "vnet" {
  source = "github.com/Narcoleptic-Fox/tf-azure//networking/vnet"

  name                = "vnet-${module.naming.prefix}"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  # ...
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
| name | Name of the virtual network | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| address_space | Address space CIDR blocks | `list(string)` | n/a | yes |
| dns_servers | Custom DNS servers | `list(string)` | `[]` | no |
| ddos_protection_plan_id | DDoS protection plan ID | `string` | `null` | no |
| subnets | Map of subnet configurations | `map(object)` | `{}` | no |
| private_dns_zone_links | Private DNS zones to link | `map(object)` | `{}` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Virtual network ID |
| name | Virtual network name |
| address_space | VNet address space |
| subnet_ids | Map of subnet names to IDs |
| subnet_address_prefixes | Map of subnet names to address prefixes |
| nsg_ids | Map of subnet names to NSG IDs |
| dns_zone_link_ids | Map of DNS zone link names to IDs |

## Security Considerations

- **NSGs by default**: Each subnet gets an NSG unless explicitly disabled
- **Private endpoints**: Use `private_endpoint_network_policies = "Enabled"` for private endpoint subnets
- **Service endpoints**: Enable only required service endpoints
- **DDoS Protection**: Consider enabling for public-facing workloads

## Service Endpoint Values

Common service endpoints:
- `Microsoft.Storage`
- `Microsoft.Sql`
- `Microsoft.KeyVault`
- `Microsoft.AzureCosmosDB`
- `Microsoft.ServiceBus`
- `Microsoft.EventHub`
- `Microsoft.ContainerRegistry`
- `Microsoft.Web`

## Subnet Delegation Services

Common delegations:
- `Microsoft.App/environments` - Container Apps
- `Microsoft.Web/serverFarms` - App Service/Functions
- `Microsoft.ContainerInstance/containerGroups` - Container Instances
- `Microsoft.DBforPostgreSQL/flexibleServers` - PostgreSQL Flexible Server
- `Microsoft.DBforMySQL/flexibleServers` - MySQL Flexible Server
