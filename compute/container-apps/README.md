# Azure Container Apps Module

Creates Azure Container Apps Environment and Container Apps for serverless container workloads with Dapr integration support.

## Features

- 🐳 Container Apps Environment with VNet integration
- 🌐 External or internal ingress
- 🔐 Secrets from values or Key Vault references
- 🔗 Dapr sidecar integration
- 📊 HTTP and custom scale rules
- 🎯 Workload profiles support

## Usage

### Basic Container App

```hcl
module "container_app" {
  source = "github.com/Narcoleptic-Fox/tf-azure//compute/container-apps"

  name                         = "api-app"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = "eastus2"
  container_app_environment_id = azurerm_container_app_environment.main.id

  identity_type = "SystemAssigned"

  ingress = {
    external_enabled = true
    target_port      = 8080
    traffic_weight = [{
      percentage      = 100
      latest_revision = true
    }]
  }

  template = {
    min_replicas = 1
    max_replicas = 10

    containers = [{
      name   = "api"
      image  = "myacr.azurecr.io/api:latest"
      cpu    = 0.5
      memory = "1Gi"

      env = [
        { name = "ASPNETCORE_ENVIRONMENT", value = "Production" }
      ]

      liveness_probe = {
        port = 8080
        path = "/health"
      }

      readiness_probe = {
        port = 8080
        path = "/ready"
      }
    }]

    http_scale_rules = [{
      name                = "http-scaling"
      concurrent_requests = 100
    }]
  }

  tags = {
    environment = "production"
  }
}
```

### With Environment Creation and VNet Integration

```hcl
module "container_app" {
  source = "github.com/Narcoleptic-Fox/tf-azure//compute/container-apps"

  name                = "api-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"

  # Create environment
  create_environment             = true
  environment_name               = "cae-prod-001"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id       = module.vnet.subnet_ids["snet-container-apps"]
  internal_load_balancer_enabled = true
  zone_redundancy_enabled        = true

  # Use user-assigned identity for ACR
  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.app.id]

  registries = [{
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.app.id
  }]

  ingress = {
    external_enabled = false  # Internal only
    target_port      = 8080
    traffic_weight = [{
      percentage      = 100
      latest_revision = true
    }]
  }

  template = {
    min_replicas = 2
    max_replicas = 20

    containers = [{
      name   = "api"
      image  = "${azurerm_container_registry.main.login_server}/api:latest"
      cpu    = 1.0
      memory = "2Gi"
    }]
  }

  tags = {
    environment = "production"
  }
}
```

### With Dapr and Key Vault Secrets

```hcl
module "container_app" {
  source = "github.com/Narcoleptic-Fox/tf-azure//compute/container-apps"

  name                         = "order-processor"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = "eastus2"
  container_app_environment_id = azurerm_container_app_environment.main.id

  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.app.id]

  # Key Vault secrets
  secrets = {
    "db-connection" = {
      key_vault_secret_id = azurerm_key_vault_secret.db_connection.versionless_id
      identity            = azurerm_user_assigned_identity.app.id
    }
    "api-key" = {
      key_vault_secret_id = azurerm_key_vault_secret.api_key.versionless_id
      identity            = azurerm_user_assigned_identity.app.id
    }
  }

  # Dapr configuration
  dapr = {
    app_id       = "order-processor"
    app_port     = 8080
    app_protocol = "http"
  }

  template = {
    min_replicas = 1
    max_replicas = 5

    containers = [{
      name   = "processor"
      image  = "myacr.azurecr.io/order-processor:latest"
      cpu    = 0.5
      memory = "1Gi"

      env = [
        { name = "DATABASE_URL", secret_name = "db-connection" },
        { name = "API_KEY", secret_name = "api-key" }
      ]
    }]
  }

  tags = {
    environment = "production"
  }
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
| name | Container App name | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| create_environment | Create new environment | `bool` | `false` | no |
| container_app_environment_id | Existing environment ID | `string` | `null` | no |
| identity_type | Managed identity type | `string` | `"SystemAssigned"` | no |
| ingress | Ingress configuration | `object` | `null` | no |
| dapr | Dapr configuration | `object` | `null` | no |
| template | Container template | `object` | n/a | yes |
| secrets | App secrets | `map(object)` | `{}` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Container App ID |
| name | Container App name |
| fqdn | Ingress FQDN |
| latest_revision_fqdn | Latest revision FQDN |
| outbound_ip_addresses | Outbound IPs |
| identity_principal_id | System identity principal ID |
| environment_id | Environment ID |
| environment_static_ip | Environment static IP |

## Security Considerations

- **Internal Load Balancer**: Enable for private-only access
- **Key Vault Secrets**: Use Key Vault references instead of plain text
- **Managed Identity**: Required for ACR and Key Vault access
- **IP Restrictions**: Use `ip_security_restrictions` to limit ingress
- **VNet Integration**: Requires /23 subnet minimum

## Subnet Requirements

Container Apps Environment requires a dedicated subnet:
- Minimum size: /23 (512 addresses)
- Recommended size: /21 for production
- Must have delegation: `Microsoft.App/environments`

```hcl
# In your VNet module
subnets = {
  "snet-container-apps" = {
    address_prefix = "10.0.2.0/23"
    delegation = {
      name         = "container-apps"
      service_name = "Microsoft.App/environments"
      actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
```

## Workload Profiles

| Profile Type | vCPU | Memory | Use Case |
|--------------|------|--------|----------|
| Consumption | 0.25-4 | 0.5-8 GB | General purpose, pay-per-use |
| D4 | 4 | 16 GB | Memory-intensive |
| D8 | 8 | 32 GB | Compute-intensive |
| D16 | 16 | 64 GB | High-performance |
| E4 | 4 | 32 GB | Memory-optimized |
