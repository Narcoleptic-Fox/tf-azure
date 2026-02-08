# Azure Virtual WAN Module

Creates an Azure Virtual WAN with hubs for multi-region connectivity, including VPN and ExpressRoute gateway options.

## Features

- 🌐 Virtual WAN with multiple regional hubs
- 🔗 VNet connections to hubs
- 🔒 Site-to-Site VPN Gateway
- ⚡ ExpressRoute Gateway
- 👤 Point-to-Site VPN Gateway
- 🛣️ Custom routing tables and static routes

## Usage

### Basic Virtual WAN with Single Hub

```hcl
module "vwan" {
  source = "github.com/Narcoleptic-Fox/tf-azure//networking/virtual-wan"

  name                = "vwan-enterprise-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"

  hubs = {
    "eastus2" = {
      name           = "vhub-eastus2-001"
      location       = "eastus2"
      address_prefix = "10.100.0.0/23"
    }
  }

  tags = {
    environment = "production"
    managed_by  = "terraform"
  }
}
```

### Multi-Region with VPN and ExpressRoute

```hcl
module "vwan" {
  source = "github.com/Narcoleptic-Fox/tf-azure//networking/virtual-wan"

  name                = "vwan-global-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"
  type                = "Standard"

  hubs = {
    "eastus2" = {
      name           = "vhub-eastus2-001"
      location       = "eastus2"
      address_prefix = "10.100.0.0/23"

      vpn_gateway = {
        name       = "vpngw-eastus2-001"
        scale_unit = 2
        bgp_asn    = 65515
      }

      expressroute_gateway = {
        name        = "ergw-eastus2-001"
        scale_units = 1
      }
    }

    "westeurope" = {
      name           = "vhub-westeurope-001"
      location       = "westeurope"
      address_prefix = "10.101.0.0/23"

      vpn_gateway = {
        name       = "vpngw-westeurope-001"
        scale_unit = 1
      }
    }
  }

  vnet_connections = {
    "app-vnet-eastus2" = {
      hub_key = "eastus2"
      vnet_id = module.vnet_eastus2.id
    }
    "app-vnet-westeurope" = {
      hub_key = "westeurope"
      vnet_id = module.vnet_westeurope.id
    }
  }

  tags = {
    environment = "production"
    managed_by  = "terraform"
  }
}
```

### With Custom Routing

```hcl
module "vwan" {
  source = "github.com/Narcoleptic-Fox/tf-azure//networking/virtual-wan"

  name                = "vwan-enterprise-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"

  hubs = {
    "main" = {
      name           = "vhub-main-001"
      location       = "eastus2"
      address_prefix = "10.100.0.0/23"
    }
  }

  vnet_connections = {
    "spoke-vnet" = {
      hub_key                   = "main"
      vnet_id                   = module.spoke_vnet.id
      internet_security_enabled = true

      routing = {
        labels = ["production"]
        static_vnet_routes = [
          {
            name                = "to-nva"
            address_prefixes    = ["0.0.0.0/0"]
            next_hop_ip_address = "10.0.1.4"
          }
        ]
      }
    }
  }

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
| name | Virtual WAN name | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region for Virtual WAN | `string` | n/a | yes |
| type | Basic or Standard | `string` | `"Standard"` | no |
| disable_vpn_encryption | Disable VPN encryption | `bool` | `false` | no |
| allow_branch_to_branch_traffic | Allow branch-to-branch | `bool` | `true` | no |
| hubs | Map of hub configurations | `map(object)` | `{}` | no |
| vnet_connections | Map of VNet connections | `map(object)` | `{}` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Virtual WAN ID |
| name | Virtual WAN name |
| hub_ids | Map of hub keys to IDs |
| hub_default_route_table_ids | Map of hub keys to default route table IDs |
| vnet_connection_ids | Map of connection names to IDs |
| vpn_gateway_ids | Map of hub keys to VPN Gateway IDs |
| expressroute_gateway_ids | Map of hub keys to ExpressRoute Gateway IDs |

## Security Considerations

- **VPN Encryption**: Keep enabled (default) unless specific requirements
- **Branch-to-Branch**: Disable if branches should not communicate directly
- **Internet Security**: Enable for VNet connections to route internet traffic through secured hub
- **Routing**: Use custom routes to force traffic through NVAs or Azure Firewall

## Hub Sizing

| Scale Unit | Bandwidth | Concurrent S2S Tunnels |
|------------|-----------|------------------------|
| 1 | 500 Mbps | 500 |
| 2 | 1 Gbps | 1000 |
| 20 | 10 Gbps | 10000 |

## Architecture Patterns

### Hub-and-Spoke with Virtual WAN
Virtual WAN simplifies hub-spoke topologies by providing managed routing between all connected VNets and branches.

### Global Transit Network
Connect multiple regional hubs for automatic any-to-any connectivity across regions.

### Secured Virtual Hub
Integrate Azure Firewall in hubs for centralized security policy enforcement.
