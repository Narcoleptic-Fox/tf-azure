# Virtual WAN Module

Multi-region hub-and-spoke connectivity.

## Features

- [ ] Virtual WAN resource
- [ ] Virtual Hubs (multi-region)
- [ ] VNet connections
- [ ] VPN Gateway integration
- [ ] ExpressRoute Gateway
- [ ] Secure Hub (Azure Firewall)
- [ ] Routing intent

## Usage (Coming Soon)

```hcl
module "vwan" {
  source = "./modules/tf-azure/networking/virtual-wan"
  
  name                = "${module.naming.prefix}-vwan"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  
  hubs = {
    eastus = {
      location = "eastus"
      address_prefix = "10.0.0.0/24"
    }
  }
  
  tags = module.tags.azure_tags
}
```
