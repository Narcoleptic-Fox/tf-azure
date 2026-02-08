# Container Apps Module

Serverless containers with auto-scaling.

## Features

- [ ] Container Apps Environment
- [ ] Managed identity
- [ ] HTTPS ingress
- [ ] Scale rules (HTTP/Queue/Custom)
- [ ] Secrets from Key Vault
- [ ] Dapr integration
- [ ] Custom domains

## Usage (Coming Soon)

```hcl
module "app" {
  source = "./modules/tf-azure/compute/container-apps"
  
  name                = "${module.naming.prefix}-api"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  container_image = "myregistry.azurecr.io/api:latest"
  
  environment_variables = {
    DATABASE_URL = "@Microsoft.KeyVault(SecretUri=...)"
  }
  
  ingress = {
    external = true
    port     = 8080
  }
  
  scale = {
    min_replicas = 1
    max_replicas = 10
  }
  
  tags = module.tags.azure_tags
}
```
