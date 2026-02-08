# Azure Storage Account Module

Creates a secure Azure Storage Account with Blob, File, Queue, and Table services, private endpoints, customer-managed keys, and lifecycle management.

## Features

- 🔒 Secure by default (TLS 1.2, no public blob access)
- 📦 Blob, File, Queue, and Table services
- 🔐 Private endpoints for each subresource
- 🔑 Customer-managed keys option
- ♻️ Lifecycle management policies
- 🆔 Managed identity support
- 📊 Versioning and soft delete

## Usage

### Secure Storage Account

```hcl
module "storage" {
  source = "github.com/Narcoleptic-Fox/tf-azure//storage/storage-account"

  name                = "stproddata001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"

  account_replication_type = "GRS"

  # Security defaults
  shared_access_key_enabled       = false  # Force Entra ID auth
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  identity_type = "SystemAssigned"

  # Blob protection
  blob_properties = {
    versioning_enabled              = true
    delete_retention_days           = 30
    container_delete_retention_days = 30
  }

  # Network isolation
  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  # Private endpoints
  private_endpoints = {
    "blob" = {
      subnet_id           = module.vnet.subnet_ids["snet-private-endpoints"]
      private_dns_zone_id = module.dns_blob.id
    }
  }

  tags = {
    environment = "production"
  }
}
```

### Storage with Containers and Lifecycle

```hcl
module "storage" {
  source = "github.com/Narcoleptic-Fox/tf-azure//storage/storage-account"

  name                     = "stlogsarchive001"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = "eastus2"
  account_replication_type = "LRS"

  containers = {
    "logs" = {
      access_type = "private"
    }
    "archive" = {
      access_type = "private"
    }
  }

  lifecycle_rules = [
    {
      name         = "logs-to-cool"
      prefix_match = ["logs/"]
      blob_types   = ["blockBlob"]
      base_blob = {
        tier_to_cool_after_days    = 30
        tier_to_archive_after_days = 90
        delete_after_days          = 365
      }
    },
    {
      name       = "delete-old-versions"
      blob_types = ["blockBlob"]
      version = {
        delete_after_days = 90
      }
    }
  ]

  tags = {
    environment = "production"
  }
}
```

### Data Lake Storage (Gen2)

```hcl
module "datalake" {
  source = "github.com/Narcoleptic-Fox/tf-azure//storage/storage-account"

  name                     = "dlproddata001"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = "eastus2"
  account_replication_type = "ZRS"

  # Enable HNS for Data Lake Gen2
  is_hns_enabled = true

  # User-assigned identity for CMK
  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.storage.id]

  # Customer-managed key
  customer_managed_key = {
    key_vault_key_id          = azurerm_key_vault_key.storage.versionless_id
    user_assigned_identity_id = azurerm_user_assigned_identity.storage.id
  }

  private_endpoints = {
    "dfs" = {
      subnet_id           = module.vnet.subnet_ids["snet-private-endpoints"]
      private_dns_zone_id = module.dns_dfs.id
    }
    "blob" = {
      subnet_id           = module.vnet.subnet_ids["snet-private-endpoints"]
      private_dns_zone_id = module.dns_blob.id
    }
  }

  tags = {
    environment = "production"
  }
}
```

### Static Website with CDN

```hcl
module "static_storage" {
  source = "github.com/Narcoleptic-Fox/tf-azure//storage/storage-account"

  name                     = "stwebprod001"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = "eastus2"
  account_replication_type = "LRS"

  # Enable static website
  static_website = {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  # Allow public access for static website
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  blob_properties = {
    cors_rules = [{
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD"]
      allowed_origins    = ["https://example.com"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }]
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
| name | Storage account name (3-24 lowercase alphanumeric) | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| account_tier | Standard or Premium | `string` | `"Standard"` | no |
| account_replication_type | LRS, GRS, ZRS, etc. | `string` | `"GRS"` | no |
| shared_access_key_enabled | Enable access keys | `bool` | `false` | no |
| public_network_access_enabled | Enable public access | `bool` | `false` | no |
| is_hns_enabled | Enable Data Lake Gen2 | `bool` | `false` | no |
| containers | Blob containers to create | `map(object)` | `{}` | no |
| file_shares | File shares to create | `map(object)` | `{}` | no |
| lifecycle_rules | Lifecycle policies | `list(object)` | `[]` | no |
| private_endpoints | Private endpoints | `map(object)` | `{}` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Storage account ID |
| name | Storage account name |
| primary_blob_endpoint | Primary blob endpoint |
| primary_file_endpoint | Primary file endpoint |
| primary_dfs_endpoint | Primary DFS endpoint |
| primary_web_endpoint | Static website endpoint |
| identity_principal_id | System identity principal ID |
| container_ids | Map of container names to IDs |
| private_endpoint_ips | Map of subresources to private IPs |

## Security Considerations

- **Disable Access Keys**: Set `shared_access_key_enabled = false` to force Entra ID authentication
- **No Public Blob Access**: Keep `allow_nested_items_to_be_public = false`
- **Private Endpoints**: Use for production workloads
- **TLS 1.2**: Minimum version by default
- **CMK Encryption**: Use customer-managed keys for sensitive data
- **Infrastructure Encryption**: Double encryption option available

## Private DNS Zones

| Subresource | DNS Zone |
|-------------|----------|
| blob | `privatelink.blob.core.windows.net` |
| file | `privatelink.file.core.windows.net` |
| queue | `privatelink.queue.core.windows.net` |
| table | `privatelink.table.core.windows.net` |
| web | `privatelink.web.core.windows.net` |
| dfs | `privatelink.dfs.core.windows.net` |

## Replication Types

| Type | Description | Use Case |
|------|-------------|----------|
| LRS | 3 copies in one datacenter | Dev/test, non-critical |
| ZRS | 3 copies across zones | Production, high availability |
| GRS | LRS + async copy to paired region | Disaster recovery |
| GZRS | ZRS + async copy to paired region | Maximum protection |
