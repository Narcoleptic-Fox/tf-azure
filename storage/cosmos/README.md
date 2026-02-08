# Cosmos DB Module

Globally distributed database with security baseline.

## Features

- [ ] SQL API (with other APIs planned)
- [ ] Customer-managed encryption
- [ ] Private endpoint
- [ ] Automatic failover
- [ ] Backup policies
- [ ] Throughput management (autoscale)
- [ ] Diagnostic settings

## Usage (Coming Soon)

```hcl
module "cosmos" {
  source = "./modules/tf-azure/storage/cosmos"
  
  name                = "${module.naming.prefix}-cosmos"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  kind = "GlobalDocumentDB"  # SQL API
  
  databases = {
    app = {
      throughput = 400
      containers = [
        { name = "users", partition_key = "/userId" },
        { name = "orders", partition_key = "/orderId" }
      ]
    }
  }
  
  tags = module.tags.azure_tags
}
```
