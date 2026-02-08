# Azure Cosmos DB Module

Creates an Azure Cosmos DB account with configurable API, geo-replication, private endpoint, and backup policies.

## Features

- 🌍 SQL API (default), with MongoDB/Cassandra/Gremlin/Table capability options
- 🔄 Multi-region writes option
- 🔐 Private endpoint support
- 💾 Continuous or periodic backups
- 🆔 Managed identity authentication
- ⚡ Serverless capability option

## Usage

### Basic SQL API Cosmos DB

```hcl
module "cosmos" {
  source = "github.com/Narcoleptic-Fox/tf-azure//storage/cosmos"

  name                = "cosmos-app-prod-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"

  # Security defaults
  public_network_access_enabled  = false
  local_authentication_disabled  = true  # Use Entra ID

  identity_type = "SystemAssigned"

  geo_locations = [
    { location = "eastus2", failover_priority = 0, zone_redundant = true },
    { location = "westus2", failover_priority = 1, zone_redundant = true }
  ]

  # Continuous backup (PITR)
  backup_policy = {
    type               = "Continuous"
    tier               = "Continuous30Days"
    storage_redundancy = "Geo"
  }

  # Private endpoint
  private_endpoint = {
    subnet_id           = module.vnet.subnet_ids["snet-private-endpoints"]
    private_dns_zone_id = module.dns_cosmos.id
  }

  sql_databases = {
    "appdb" = {
      autoscale_max_throughput = 4000
      containers = {
        "items" = {
          partition_key_paths = ["/partitionKey"]
          default_ttl         = -1  # No expiration
        }
        "sessions" = {
          partition_key_paths = ["/userId"]
          default_ttl         = 3600  # 1 hour
        }
      }
    }
  }

  tags = {
    environment = "production"
  }
}
```

### Serverless Cosmos DB

```hcl
module "cosmos_serverless" {
  source = "github.com/Narcoleptic-Fox/tf-azure//storage/cosmos"

  name                = "cosmos-events-prod-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"

  capabilities = ["EnableServerless"]

  geo_locations = [
    { location = "eastus2", failover_priority = 0 }
  ]

  sql_databases = {
    "events" = {
      containers = {
        "telemetry" = {
          partition_key_paths = ["/deviceId"]
          indexing_policy = {
            indexing_mode  = "consistent"
            excluded_paths = ["/*"]
            included_paths = ["/deviceId/?", "/timestamp/?"]
          }
        }
      }
    }
  }

  tags = {
    environment = "production"
  }
}
```

### Multi-Region with Writes

```hcl
module "cosmos_global" {
  source = "github.com/Narcoleptic-Fox/tf-azure//storage/cosmos"

  name                = "cosmos-global-prod-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"

  # Enable multi-master
  multiple_write_locations_enabled = true
  consistency_level                = "Session"  # Recommended for multi-master

  geo_locations = [
    { location = "eastus2", failover_priority = 0, zone_redundant = true },
    { location = "westeurope", failover_priority = 1, zone_redundant = true },
    { location = "southeastasia", failover_priority = 2, zone_redundant = true }
  ]

  sql_databases = {
    "globaldb" = {
      autoscale_max_throughput = 10000
      containers = {
        "data" = {
          partition_key_paths = ["/region", "/id"]
          conflict_resolution_policy = {
            mode                     = "LastWriterWins"
            conflict_resolution_path = "/_ts"
          }
        }
      }
    }
  }

  tags = {
    environment = "production"
  }
}
```

### With Analytical Storage (Synapse Link)

```hcl
module "cosmos_analytics" {
  source = "github.com/Narcoleptic-Fox/tf-azure//storage/cosmos"

  name                = "cosmos-analytics-prod-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"

  analytical_storage_enabled     = true
  analytical_storage_schema_type = "FullFidelity"

  geo_locations = [
    { location = "eastus2", failover_priority = 0 }
  ]

  sql_databases = {
    "analyticsdb" = {
      containers = {
        "transactions" = {
          partition_key_paths    = ["/customerId"]
          analytical_storage_ttl = -1  # Enable analytical storage, no TTL
        }
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
| name | Cosmos DB account name | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Primary Azure region | `string` | n/a | yes |
| kind | API kind | `string` | `"GlobalDocumentDB"` | no |
| public_network_access_enabled | Enable public access | `bool` | `false` | no |
| local_authentication_disabled | Disable key auth | `bool` | `true` | no |
| consistency_level | Default consistency | `string` | `"Session"` | no |
| geo_locations | Geo-replication config | `list(object)` | n/a | yes |
| capabilities | Features to enable | `list(string)` | `[]` | no |
| backup_policy | Backup configuration | `object` | Continuous | no |
| sql_databases | SQL databases/containers | `map(object)` | `{}` | no |
| private_endpoint | Private endpoint config | `object` | `null` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Cosmos DB account ID |
| name | Account name |
| endpoint | Primary endpoint |
| read_endpoints | Read endpoints per region |
| write_endpoints | Write endpoints |
| identity_principal_id | System identity principal ID |
| sql_database_ids | Map of database names to IDs |
| sql_container_ids | Map of container keys to IDs |
| private_endpoint_ip | Private endpoint IP |

## Security Considerations

- **Disable Local Auth**: Set `local_authentication_disabled = true` to force Entra ID
- **Private Endpoint**: Use for production workloads
- **Network ACL**: Enable virtual network filter and restrict access
- **TLS 1.2**: Minimum version enforced by default
- **Backup**: Use continuous backup for PITR capability

## Consistency Levels

| Level | Guarantees | Performance | Use Case |
|-------|------------|-------------|----------|
| Strong | Linearizability | Lower | Financial transactions |
| Bounded Staleness | Consistent prefix, bounded lag | Medium | Gaming leaderboards |
| Session | Read your writes | Higher | User sessions (default) |
| Consistent Prefix | Never out of order | Higher | Social feeds |
| Eventual | No ordering guarantee | Highest | Telemetry, non-critical |

## Private DNS Zones

| API | DNS Zone |
|-----|----------|
| SQL | `privatelink.documents.azure.com` |
| MongoDB | `privatelink.mongo.cosmos.azure.com` |
| Cassandra | `privatelink.cassandra.cosmos.azure.com` |
| Gremlin | `privatelink.gremlin.cosmos.azure.com` |
| Table | `privatelink.table.cosmos.azure.com` |
