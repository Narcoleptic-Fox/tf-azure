# Azure Front Door Module

Global CDN with WAF and intelligent routing.

## Features

- [ ] Standard or Premium tier
- [ ] Multiple origins (Storage, App Service, Custom)
- [ ] WAF policies
- [ ] Custom domains with managed certificates
- [ ] Caching rules
- [ ] Health probes
- [ ] Private Link origins

## Usage (Coming Soon)

```hcl
module "frontdoor" {
  source = "./modules/tf-azure/cdn/front-door"
  
  name                = "${module.naming.prefix}-fd"
  resource_group_name = azurerm_resource_group.main.name
  
  sku = "Premium_AzureFrontDoor"
  
  origins = {
    api = {
      host_name = module.container_app.fqdn
      private_link = {
        id = module.container_app.id
      }
    }
    static = {
      host_name = module.storage.primary_web_host
    }
  }
  
  waf_policy_id = module.waf.policy_id
  
  tags = module.tags.azure_tags
}
```
