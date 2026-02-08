# VM Baseline Module

Hardened Azure VMs with managed identity and security.

## Features

- [ ] Managed identity (no passwords)
- [ ] Azure AD login
- [ ] Disk encryption (platform or CMK)
- [ ] Boot diagnostics
- [ ] Auto-shutdown (dev/test)
- [ ] Update management
- [ ] Azure Monitor agent

## Usage (Coming Soon)

```hcl
module "vm" {
  source = "./modules/tf-azure/compute/vm-baseline"
  
  name                = "${module.naming.vm_name}-web"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  size      = "Standard_B2s"
  subnet_id = module.vnet.subnet_ids["app"]
  
  os_type = "linux"
  image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
  }
  
  tags = module.tags.azure_tags
}
```
