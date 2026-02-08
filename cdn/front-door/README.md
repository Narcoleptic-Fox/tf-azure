# Azure Front Door Module

Creates an Azure Front Door (Standard/Premium) with origins, routes, rule sets, and WAF integration.

## Security Features (Enforced)

- ✅ **HTTPS only** — HTTP automatically redirects to HTTPS
- ✅ **TLS 1.2 minimum** — Default for all custom domains
- ✅ **Certificate validation** — Origin certificate check enabled by default
- ✅ **WAF ready** — Simple integration via `waf_policy_id`
- ✅ **Private Link** — Available with Premium SKU

## Usage

### Basic Static Website

```hcl
module "naming" {
  source      = "github.com/Narcoleptic-Fox/tf-security//core/naming"
  project     = "myapp"
  environment = "prod"
  region      = "eastus"
}

module "tags" {
  source      = "github.com/Narcoleptic-Fox/tf-security//core/tagging"
  project     = "myapp"
  environment = "prod"
  owner       = "platform"
  cost_center = "engineering"
}

module "front_door" {
  source = "github.com/Narcoleptic-Fox/tf-azure//cdn/front-door"

  name                = "fd-${module.naming.prefix}"
  resource_group_name = azurerm_resource_group.main.name

  origin_groups = {
    storage = {
      health_probe = {
        path     = "/"
        protocol = "Https"
      }
      origins = [
        {
          name               = "primary"
          host_name          = azurerm_storage_account.main.primary_web_host
          origin_host_header = azurerm_storage_account.main.primary_web_host
        }
      ]
    }
  }

  endpoints = {
    main = { enabled = true }
  }

  routes = {
    default = {
      endpoint_name     = "main"
      origin_group_name = "storage"
      origin_names      = ["primary"]
      
      cache = {
        compression_enabled = true
      }
    }
  }

  tags = module.tags.azure_tags
}
```

### Multiple Origins with Failover

```hcl
module "front_door" {
  source = "github.com/Narcoleptic-Fox/tf-azure//cdn/front-door"

  name                = "fd-api"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Premium_AzureFrontDoor"

  origin_groups = {
    api = {
      health_probe = {
        path         = "/health"
        protocol     = "Https"
        request_type = "GET"
      }
      origins = [
        {
          name               = "primary"
          host_name          = azurerm_container_app.primary.latest_revision_fqdn
          origin_host_header = azurerm_container_app.primary.latest_revision_fqdn
          priority           = 1
        },
        {
          name               = "secondary"
          host_name          = azurerm_container_app.secondary.latest_revision_fqdn
          origin_host_header = azurerm_container_app.secondary.latest_revision_fqdn
          priority           = 2
        }
      ]
    }
  }

  endpoints = {
    api = { enabled = true }
  }

  routes = {
    api = {
      endpoint_name     = "api"
      origin_group_name = "api"
      origin_names      = ["primary", "secondary"]
      
      # No caching for API
      forwarding_protocol = "HttpsOnly"
    }
  }

  tags = module.tags.azure_tags
}
```

### With Custom Domain and WAF

```hcl
module "front_door" {
  source = "github.com/Narcoleptic-Fox/tf-azure//cdn/front-door"

  name                = "fd-web"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Premium_AzureFrontDoor"

  origin_groups = {
    web = {
      health_probe = { path = "/" }
      origins = [
        {
          name      = "webapp"
          host_name = azurerm_linux_web_app.main.default_hostname
        }
      ]
    }
  }

  endpoints = {
    web = { enabled = true }
  }

  custom_domains = {
    "www.example.com" = {
      dns_zone_id             = azurerm_dns_zone.main.id
      dns_zone_resource_group = azurerm_resource_group.main.name
      certificate_type        = "ManagedCertificate"
      endpoint_name           = "web"
      create_dns_record       = true
    }
  }

  routes = {
    web = {
      endpoint_name          = "web"
      origin_group_name      = "web"
      origin_names           = ["webapp"]
      custom_domain_names    = ["www.example.com"]
      link_to_default_domain = false
      
      cache = {
        compression_enabled = true
      }
    }
  }

  # WAF integration
  waf_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.id

  tags = module.tags.azure_tags
}
```

### With Rule Sets (URL Rewrite/Redirect)

```hcl
module "front_door" {
  source = "github.com/Narcoleptic-Fox/tf-azure//cdn/front-door"

  name                = "fd-rules"
  resource_group_name = azurerm_resource_group.main.name

  origin_groups = {
    web = {
      health_probe = { path = "/" }
      origins = [
        {
          name      = "primary"
          host_name = "backend.example.com"
        }
      ]
    }
  }

  endpoints = {
    main = { enabled = true }
  }

  rule_sets = {
    security_headers = {
      rules = [
        {
          name  = "AddSecurityHeaders"
          order = 1
          actions = {
            response_headers = [
              {
                header_action = "Append"
                header_name   = "X-Content-Type-Options"
                value         = "nosniff"
              },
              {
                header_action = "Append"
                header_name   = "X-Frame-Options"
                value         = "DENY"
              },
              {
                header_action = "Append"
                header_name   = "Strict-Transport-Security"
                value         = "max-age=31536000; includeSubDomains"
              }
            ]
          }
        }
      ]
    }
    redirects = {
      rules = [
        {
          name  = "OldPathRedirect"
          order = 1
          conditions = {
            request_uri = {
              operator     = "BeginsWith"
              match_values = ["/old-path"]
            }
          }
          actions = {
            url_redirect = {
              redirect_type    = "Moved"
              destination_path = "/new-path"
            }
          }
        }
      ]
    }
  }

  routes = {
    default = {
      endpoint_name     = "main"
      origin_group_name = "web"
      origin_names      = ["primary"]
      rule_set_names    = ["security_headers", "redirects"]
    }
  }

  tags = module.tags.azure_tags
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
| name | Profile name | `string` | n/a | yes |
| resource_group_name | Resource group | `string` | n/a | yes |
| sku_name | SKU (Standard/Premium) | `string` | `"Standard_AzureFrontDoor"` | no |
| origin_groups | Origin groups with origins | `map(object)` | n/a | yes |
| endpoints | Endpoints | `map(object)` | n/a | yes |
| routes | Routes | `map(object)` | n/a | yes |
| custom_domains | Custom domains | `map(object)` | `{}` | no |
| rule_sets | Rule sets with rules | `map(object)` | `{}` | no |
| waf_policy_id | WAF policy ID | `string` | `null` | no |

See `variables.tf` for full list.

## Outputs

| Name | Description |
|------|-------------|
| profile_id | Front Door profile ID |
| endpoint_host_names | Map of endpoint host names |
| custom_domain_validation_tokens | Validation tokens for DNS |
| default_urls | Endpoint URLs |

## Notes

- **Premium vs Standard**: Private Link origins require Premium SKU
- **Custom domains**: Need DNS validation via TXT record
- **WAF**: Create `azurerm_cdn_frontdoor_firewall_policy` separately
- **Managed certificates**: Auto-provisioned, no ACM equivalent needed
