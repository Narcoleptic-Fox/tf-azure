# Azure VM Baseline Module

Creates hardened Azure Virtual Machines following security best practices with managed identities, disk encryption, and no public IP exposure.

## Features

- 🔐 Managed identity (system or user-assigned)
- 💾 Disk encryption at host with CMK support
- 🚫 No public IP (use Azure Bastion)
- 📊 Boot diagnostics (managed or custom storage)
- 🔄 Automatic OS patching
- 🛡️ Secure Boot and vTPM
- 💿 Data disk management

## Usage

### Secure Linux VM

```hcl
module "vm" {
  source = "github.com/Narcoleptic-Fox/tf-azure//compute/vm-baseline"

  name                = "vm-app-prod-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"
  
  os_type   = "Linux"
  size      = "Standard_D4s_v5"
  zone      = "1"
  subnet_id = module.vnet.subnet_ids["snet-app"]

  admin_username = "azureadmin"
  admin_ssh_key  = file("~/.ssh/id_rsa.pub")

  # Security settings
  encryption_at_host_enabled = true
  disk_encryption_set_id     = module.keyvault.disk_encryption_set_id
  identity_type              = "SystemAssigned"

  source_image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    environment = "production"
    managed_by  = "terraform"
  }
}
```

### Windows VM with Data Disks

```hcl
module "vm_windows" {
  source = "github.com/Narcoleptic-Fox/tf-azure//compute/vm-baseline"

  name                = "vm-sql-prod-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"

  os_type   = "Windows"
  size      = "Standard_D8s_v5"
  zone      = "1"
  subnet_id = module.vnet.subnet_ids["snet-data"]

  admin_username = "azureadmin"
  admin_password = var.admin_password  # Use Key Vault in production!

  # Security settings
  encryption_at_host_enabled = true
  disk_encryption_set_id     = module.keyvault.disk_encryption_set_id
  
  # User-assigned identity for Key Vault access
  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.sql.id]

  source_image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  # SQL Server data disks
  data_disks = {
    "data" = {
      disk_size_gb = 256
      lun          = 0
      caching      = "ReadOnly"
    }
    "log" = {
      disk_size_gb = 128
      lun          = 1
      caching      = "None"
    }
    "temp" = {
      disk_size_gb         = 64
      storage_account_type = "Premium_LRS"
      lun                  = 2
      caching              = "ReadOnly"
    }
  }

  tags = {
    environment = "production"
  }
}
```

### Integration with tf-security

```hcl
module "naming" {
  source = "github.com/Narcoleptic-Fox/tf-security//core/naming"

  project     = "navigator"
  environment = "prod"
  region      = "eastus2"
}

module "vm" {
  source = "github.com/Narcoleptic-Fox/tf-azure//compute/vm-baseline"

  name                = "vm-${module.naming.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"
  # ...
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
| name | VM name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| os_type | Linux or Windows | `string` | n/a | yes |
| subnet_id | Subnet ID for NIC | `string` | n/a | yes |
| size | VM size | `string` | `"Standard_D2s_v5"` | no |
| zone | Availability zone | `string` | `null` | no |
| admin_username | Admin username | `string` | `"azureadmin"` | no |
| admin_password | Admin password (Windows) | `string` | `null` | no |
| admin_ssh_key | SSH public key (Linux) | `string` | `null` | no |
| encryption_at_host_enabled | Enable host encryption | `bool` | `true` | no |
| disk_encryption_set_id | CMK encryption set ID | `string` | `null` | no |
| identity_type | Managed identity type | `string` | `"SystemAssigned"` | no |
| identity_ids | User-assigned identity IDs | `list(string)` | `[]` | no |
| source_image | Image reference | `object` | Ubuntu 22.04 | no |
| data_disks | Data disk configurations | `map(object)` | `{}` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | VM resource ID |
| name | VM name |
| private_ip_address | Private IP address |
| identity_principal_id | System-assigned identity principal ID |
| data_disk_ids | Map of data disk names to IDs |

## Security Considerations

- **No Public IP**: VMs have no public IP. Use Azure Bastion for access.
- **Encryption at Host**: Enables encryption of VM temp disks and caches
- **Managed Identity**: Use for Azure service access instead of credentials
- **CMK Encryption**: Optional customer-managed keys via disk encryption set
- **Secure Boot**: Enabled by default for Gen2 images
- **vTPM**: Enabled for measured boot support

## Prerequisites

### Encryption at Host
Enable the feature on your subscription:
```bash
az feature register --namespace "Microsoft.Compute" --name "EncryptionAtHost"
az feature show --namespace "Microsoft.Compute" --name "EncryptionAtHost"
az provider register --namespace "Microsoft.Compute"
```

### Disk Encryption Set
For customer-managed keys, create a disk encryption set linked to Key Vault.

## Common Images

### Linux
| OS | Publisher | Offer | SKU |
|----|-----------|-------|-----|
| Ubuntu 22.04 | Canonical | 0001-com-ubuntu-server-jammy | 22_04-lts-gen2 |
| Ubuntu 24.04 | Canonical | ubuntu-24_04-lts | server | 
| RHEL 9 | RedHat | RHEL | 9-lvm-gen2 |
| Debian 12 | Debian | debian-12 | 12-gen2 |

### Windows
| OS | Publisher | Offer | SKU |
|----|-----------|-------|-----|
| Windows Server 2022 | MicrosoftWindowsServer | WindowsServer | 2022-datacenter-g2 |
| Windows Server 2019 | MicrosoftWindowsServer | WindowsServer | 2019-datacenter-gensecond |
| Windows 11 | MicrosoftWindowsDesktop | windows-11 | win11-23h2-pro |
