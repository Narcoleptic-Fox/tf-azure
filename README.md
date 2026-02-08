# 🦊 tf-azure

**Terraform Azure infrastructure modules**

Part of the [Narcoleptic Fox](https://github.com/Narcoleptic-Fox) infrastructure toolkit.

## Overview

Production-ready Azure infrastructure patterns:
- **Networking** — VNet, Virtual WAN, DNS
- **Compute** — VMs, Container Apps, Functions
- **Storage** — Storage Accounts, Cosmos DB
- **CDN** — Azure Front Door with WAF

Pairs with [tf-security](https://github.com/Narcoleptic-Fox/tf-security) for security baselines.

## Quick Start

Add as a git submodule:

```bash
git submodule add https://github.com/Narcoleptic-Fox/tf-azure.git modules/tf-azure
git submodule add https://github.com/Narcoleptic-Fox/tf-security.git modules/tf-security
```

## Modules

### Networking

| Module | Description |
|--------|-------------|
| [`networking/vnet`](./networking/vnet/) | Virtual network with subnets |
| [`networking/virtual-wan`](./networking/virtual-wan/) | Multi-region connectivity |
| [`networking/dns`](./networking/dns/) | Private DNS zones |

### Compute

| Module | Description |
|--------|-------------|
| [`compute/vm-baseline`](./compute/vm-baseline/) | Hardened VMs |
| [`compute/container-apps`](./compute/container-apps/) | Serverless containers |
| [`compute/functions`](./compute/functions/) | Azure Functions |

### Storage

| Module | Description |
|--------|-------------|
| [`storage/storage-account`](./storage/storage-account/) | Blob/Files with encryption |
| [`storage/cosmos`](./storage/cosmos/) | Cosmos DB baseline |

### CDN

| Module | Description |
|--------|-------------|
| [`cdn/front-door`](./cdn/front-door/) | CDN + WAF |

## Usage Example

```hcl
module "naming" {
  source      = "./modules/tf-security/core/naming"
  project     = "mousing"
  environment = "prod"
  region      = "eastus"
}

module "tags" {
  source      = "./modules/tf-security/core/tagging"
  project     = "mousing"
  environment = "prod"
  owner       = "platform"
  cost_center = "engineering"
}

resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group_name
  location = "eastus"
  tags     = module.tags.azure_tags
}

module "vnet" {
  source = "./modules/tf-azure/networking/vnet"

  name                = module.naming.vnet_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
  
  tags = module.tags.azure_tags
}
```

## Related Repos

- [tf-security](https://github.com/Narcoleptic-Fox/tf-security) — Security baseline modules
- [tf-aws](https://github.com/Narcoleptic-Fox/tf-aws) — AWS infrastructure modules

## License

MIT — See [LICENSE](./LICENSE)
