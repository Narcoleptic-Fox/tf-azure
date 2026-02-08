# VNet Module

Azure Virtual Network with subnets and service endpoints.

## Features

- [ ] Configurable address space
- [ ] Multiple subnet support
- [ ] Service endpoints
- [ ] Private endpoint support
- [ ] VNet peering ready
- [ ] DNS servers configuration
- [ ] DDoS protection plan

## Planned Inputs

| Name | Description |
|------|-------------|
| `name` | VNet name |
| `resource_group_name` | Resource group |
| `location` | Azure region |
| `address_space` | CIDR blocks |
| `subnets` | Subnet definitions |
| `tags` | Resource tags |

## Planned Outputs

| Name | Description |
|------|-------------|
| `id` | VNet ID |
| `name` | VNet name |
| `subnet_ids` | Map of subnet IDs |
