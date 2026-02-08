# Azure Functions Module

Serverless functions with managed identity.

## Features

- [ ] Consumption or Premium plan
- [ ] VNet integration (Premium)
- [ ] Managed identity
- [ ] Application Insights
- [ ] Key Vault references
- [ ] Deployment slots
- [ ] Private endpoints

## Usage (Coming Soon)

```hcl
module "functions" {
  source = "./modules/tf-azure/compute/functions"
  
  name                = "${module.naming.prefix}-fn"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  runtime         = "python"
  runtime_version = "3.11"
  
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
  }
  
  tags = module.tags.azure_tags
}
```
