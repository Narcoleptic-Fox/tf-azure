# Storage Account Module

Secure Azure Storage with encryption and private endpoints.

## Features

- [ ] Blob, File, Queue, Table
- [ ] Customer-managed key encryption
- [ ] Private endpoint
- [ ] Soft delete and versioning
- [ ] Lifecycle management
- [ ] Immutable storage
- [ ] Diagnostic settings

## Usage (Coming Soon)

```hcl
module "storage" {
  source = "./modules/tf-azure/storage/storage-account"
  
  name                = module.naming.storage_account_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  containers = ["data", "logs"]
  
  private_endpoint = {
    subnet_id = module.vnet.subnet_ids["private-endpoints"]
  }
  
  tags = module.tags.azure_tags
}
```
