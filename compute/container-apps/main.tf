/**
 * # Azure Container Apps Module
 *
 * Creates Container Apps Environment and Container Apps for serverless containers.
 *
 * ## Features
 * - Container Apps Environment with VNet integration
 * - Container App with configurable ingress
 * - Secrets and environment variables
 * - Dapr integration option
 * - Workload profiles support
 */

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Container Apps Environment
# -----------------------------------------------------------------------------

resource "azurerm_container_app_environment" "this" {
  count = var.create_environment ? 1 : 0

  name                               = var.environment_name
  location                           = var.location
  resource_group_name                = var.resource_group_name
  log_analytics_workspace_id         = var.log_analytics_workspace_id
  infrastructure_subnet_id           = var.infrastructure_subnet_id
  internal_load_balancer_enabled     = var.internal_load_balancer_enabled
  zone_redundancy_enabled            = var.zone_redundancy_enabled
  infrastructure_resource_group_name = var.infrastructure_resource_group_name

  dynamic "workload_profile" {
    for_each = var.workload_profiles
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      minimum_count         = workload_profile.value.minimum_count
      maximum_count         = workload_profile.value.maximum_count
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Container App
# -----------------------------------------------------------------------------

resource "azurerm_container_app" "this" {
  name                         = var.name
  container_app_environment_id = var.create_environment ? azurerm_container_app_environment.this[0].id : var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode
  workload_profile_name        = var.workload_profile_name

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != "None" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # Container Registry
  dynamic "registry" {
    for_each = var.registries
    content {
      server               = registry.value.server
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
      identity             = registry.value.identity
    }
  }

  # Secrets
  dynamic "secret" {
    for_each = var.secrets
    content {
      name                = secret.key
      value               = secret.value.value
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = secret.value.identity
    }
  }

  # Ingress
  dynamic "ingress" {
    for_each = var.ingress != null ? [var.ingress] : []
    content {
      external_enabled           = ingress.value.external_enabled
      target_port                = ingress.value.target_port
      transport                  = ingress.value.transport
      allow_insecure_connections = ingress.value.allow_insecure_connections
      exposed_port               = ingress.value.exposed_port

      dynamic "traffic_weight" {
        for_each = ingress.value.traffic_weight != null ? ingress.value.traffic_weight : []
        content {
          percentage      = traffic_weight.value.percentage
          latest_revision = traffic_weight.value.latest_revision
          revision_suffix = traffic_weight.value.revision_suffix
          label           = traffic_weight.value.label
        }
      }

      dynamic "ip_security_restriction" {
        for_each = ingress.value.ip_security_restrictions != null ? ingress.value.ip_security_restrictions : []
        content {
          name             = ip_security_restriction.value.name
          action           = ip_security_restriction.value.action
          ip_address_range = ip_security_restriction.value.ip_address_range
          description      = ip_security_restriction.value.description
        }
      }
    }
  }

  # Dapr
  dynamic "dapr" {
    for_each = var.dapr != null ? [var.dapr] : []
    content {
      app_id       = dapr.value.app_id
      app_port     = dapr.value.app_port
      app_protocol = dapr.value.app_protocol
    }
  }

  template {
    min_replicas    = var.template.min_replicas
    max_replicas    = var.template.max_replicas
    revision_suffix = var.template.revision_suffix

    dynamic "container" {
      for_each = var.template.containers
      content {
        name    = container.value.name
        image   = container.value.image
        cpu     = container.value.cpu
        memory  = container.value.memory
        command = container.value.command
        args    = container.value.args

        dynamic "env" {
          for_each = container.value.env != null ? container.value.env : []
          content {
            name        = env.value.name
            value       = env.value.value
            secret_name = env.value.secret_name
          }
        }

        dynamic "liveness_probe" {
          for_each = container.value.liveness_probe != null ? [container.value.liveness_probe] : []
          content {
            transport               = liveness_probe.value.transport
            port                    = liveness_probe.value.port
            path                    = liveness_probe.value.path
            initial_delay           = liveness_probe.value.initial_delay
            interval_seconds        = liveness_probe.value.interval_seconds
            timeout                 = liveness_probe.value.timeout
            failure_count_threshold = liveness_probe.value.failure_count_threshold
          }
        }

        dynamic "readiness_probe" {
          for_each = container.value.readiness_probe != null ? [container.value.readiness_probe] : []
          content {
            transport               = readiness_probe.value.transport
            port                    = readiness_probe.value.port
            path                    = readiness_probe.value.path
            initial_delay           = readiness_probe.value.initial_delay
            interval_seconds        = readiness_probe.value.interval_seconds
            timeout                 = readiness_probe.value.timeout
            failure_count_threshold = readiness_probe.value.failure_count_threshold
          }
        }

        dynamic "startup_probe" {
          for_each = container.value.startup_probe != null ? [container.value.startup_probe] : []
          content {
            transport               = startup_probe.value.transport
            port                    = startup_probe.value.port
            path                    = startup_probe.value.path
            initial_delay           = startup_probe.value.initial_delay
            interval_seconds        = startup_probe.value.interval_seconds
            timeout                 = startup_probe.value.timeout
            failure_count_threshold = startup_probe.value.failure_count_threshold
          }
        }

        dynamic "volume_mounts" {
          for_each = container.value.volume_mounts != null ? container.value.volume_mounts : []
          content {
            name = volume_mounts.value.name
            path = volume_mounts.value.path
          }
        }
      }
    }

    dynamic "volume" {
      for_each = var.template.volumes != null ? var.template.volumes : []
      content {
        name         = volume.value.name
        storage_name = volume.value.storage_name
        storage_type = volume.value.storage_type
      }
    }

    dynamic "http_scale_rule" {
      for_each = var.template.http_scale_rules != null ? var.template.http_scale_rules : []
      content {
        name                = http_scale_rule.value.name
        concurrent_requests = http_scale_rule.value.concurrent_requests
      }
    }

    dynamic "custom_scale_rule" {
      for_each = var.template.custom_scale_rules != null ? var.template.custom_scale_rules : []
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata

        dynamic "authentication" {
          for_each = custom_scale_rule.value.authentication != null ? custom_scale_rule.value.authentication : []
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }
  }

  tags = var.tags
}
