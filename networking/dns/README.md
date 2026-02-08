# Azure Private DNS Module

Creates Azure Private DNS zones with VNet links and DNS records for internal name resolution.

## Features

- 🌐 Private DNS zone creation
- 🔗 VNet link management with optional auto-registration
- 📝 All record types: A, AAAA, CNAME, MX, PTR, SRV, TXT
- 🏷️ Consistent tagging

## Usage

### Basic Private DNS Zone

```hcl
module "dns_internal" {
  source = "github.com/Narcoleptic-Fox/tf-azure//networking/dns"

  zone_name           = "internal.example.com"
  resource_group_name = azurerm_resource_group.main.name

  vnet_links = {
    "main-vnet" = {
      vnet_id              = module.vnet.id
      registration_enabled = true  # Auto-register VM hostnames
    }
  }

  tags = {
    environment = "production"
    managed_by  = "terraform"
  }
}
```

### Private Link DNS Zone

```hcl
module "dns_privatelink_keyvault" {
  source = "github.com/Narcoleptic-Fox/tf-azure//networking/dns"

  zone_name           = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.dns.name

  vnet_links = {
    "hub-vnet" = {
      vnet_id = module.hub_vnet.id
    }
    "spoke-vnet" = {
      vnet_id = module.spoke_vnet.id
    }
  }

  tags = {
    environment = "production"
  }
}
```

### DNS Zone with Records

```hcl
module "dns" {
  source = "github.com/Narcoleptic-Fox/tf-azure//networking/dns"

  zone_name           = "app.internal"
  resource_group_name = azurerm_resource_group.main.name

  vnet_links = {
    "main" = {
      vnet_id = module.vnet.id
    }
  }

  a_records = {
    "api" = {
      ttl     = 300
      records = ["10.0.1.10"]
    }
    "db" = {
      ttl     = 300
      records = ["10.0.2.10", "10.0.2.11"]  # Multiple IPs for HA
    }
  }

  cname_records = {
    "www" = {
      ttl    = 300
      record = "api.app.internal"
    }
  }

  srv_records = {
    "_ldap._tcp" = {
      ttl = 300
      records = [
        {
          priority = 0
          weight   = 100
          port     = 389
          target   = "dc1.app.internal"
        }
      ]
    }
  }

  txt_records = {
    "@" = {
      ttl     = 300
      records = ["v=spf1 -all"]
    }
  }

  tags = {
    environment = "production"
  }
}
```

## Private Link DNS Zones Reference

Common Azure service private link zones:

| Service | Zone Name |
|---------|-----------|
| Storage Blob | `privatelink.blob.core.windows.net` |
| Storage File | `privatelink.file.core.windows.net` |
| Storage Queue | `privatelink.queue.core.windows.net` |
| Storage Table | `privatelink.table.core.windows.net` |
| Key Vault | `privatelink.vaultcore.azure.net` |
| SQL Database | `privatelink.database.windows.net` |
| Cosmos DB | `privatelink.documents.azure.com` |
| PostgreSQL | `privatelink.postgres.database.azure.com` |
| MySQL | `privatelink.mysql.database.azure.com` |
| ACR | `privatelink.azurecr.io` |
| Event Hub | `privatelink.servicebus.windows.net` |
| Service Bus | `privatelink.servicebus.windows.net` |
| App Config | `privatelink.azconfig.io` |
| App Service | `privatelink.azurewebsites.net` |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| zone_name | DNS zone name | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| soa_record | SOA record configuration | `object` | `null` | no |
| vnet_links | Map of VNet links | `map(object)` | `{}` | no |
| a_records | Map of A records | `map(object)` | `{}` | no |
| aaaa_records | Map of AAAA records | `map(object)` | `{}` | no |
| cname_records | Map of CNAME records | `map(object)` | `{}` | no |
| mx_records | Map of MX records | `map(object)` | `{}` | no |
| ptr_records | Map of PTR records | `map(object)` | `{}` | no |
| srv_records | Map of SRV records | `map(object)` | `{}` | no |
| txt_records | Map of TXT records | `map(object)` | `{}` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | DNS zone ID |
| name | DNS zone name |
| vnet_link_ids | Map of VNet link names to IDs |
| a_record_ids | Map of A record names to IDs |
| a_record_fqdns | Map of A record names to FQDNs |
| cname_record_ids | Map of CNAME record names to IDs |
| cname_record_fqdns | Map of CNAME record names to FQDNs |

## Security Considerations

- **Auto-registration**: Enable only for VNets where automatic VM registration is desired
- **Zone isolation**: Use separate resource groups for DNS zones with different access requirements
- **Private Link zones**: Create centrally and link to all VNets that need resolution

## Best Practices

1. **Centralized DNS**: Create private link DNS zones in a central hub resource group
2. **Link all VNets**: Ensure all VNets that need private endpoint resolution are linked
3. **Naming**: Use meaningful link names that identify the VNet being linked
4. **TTL values**: Use appropriate TTL values (shorter for dynamic records, longer for static)
