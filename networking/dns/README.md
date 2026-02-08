# DNS Module

Private DNS zones for Azure services.

## Features

- [ ] Private DNS zones
- [ ] VNet links
- [ ] A/AAAA/CNAME records
- [ ] Auto-registration
- [ ] Conditional forwarding

## Common Zones

```
privatelink.blob.core.windows.net
privatelink.database.windows.net
privatelink.vaultcore.azure.net
```

## Usage (Coming Soon)

```hcl
module "dns" {
  source = "./modules/tf-azure/networking/dns"
  
  resource_group_name = azurerm_resource_group.main.name
  vnet_id             = module.vnet.id
  
  zones = [
    "privatelink.blob.core.windows.net",
    "privatelink.vaultcore.azure.net"
  ]
  
  tags = module.tags.azure_tags
}
```
