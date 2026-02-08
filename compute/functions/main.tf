/**
 * # Azure Functions Module
 *
 * Creates Azure Functions with optional App Service Plan, VNet integration,
 * and Application Insights.
 *
 * ## Features
 * - Consumption or Premium plan
 * - VNet integration option
 * - Application Insights
 * - Key Vault references for secrets
 * - Private endpoint option
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
# Service Plan (optional)
# -----------------------------------------------------------------------------

resource "azurerm_service_plan" "this" {
  count = var.create_service_plan ? 1 : 0

  name                = var.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku_name

  maximum_elastic_worker_count = var.sku_name != "Y1" ? var.maximum_elastic_worker_count : null
  zone_balancing_enabled       = var.zone_balancing_enabled

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Linux Function App
# -----------------------------------------------------------------------------

resource "azurerm_linux_function_app" "this" {
  count = var.os_type == "Linux" ? 1 : 0

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  service_plan_id            = var.create_service_plan ? azurerm_service_plan.this[0].id : var.service_plan_id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_uses_managed_identity ? null : var.storage_account_access_key
  storage_uses_managed_identity = var.storage_uses_managed_identity

  # Security
  https_only                     = true
  public_network_access_enabled  = var.public_network_access_enabled
  key_vault_reference_identity_id = var.key_vault_reference_identity_id

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != "None" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # VNet Integration
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  site_config {
    always_on                              = var.sku_name != "Y1" ? var.always_on : false
    http2_enabled                          = var.http2_enabled
    minimum_tls_version                    = var.minimum_tls_version
    ftps_state                             = var.ftps_state
    vnet_route_all_enabled                 = var.vnet_route_all_enabled
    application_insights_key               = var.application_insights_key
    application_insights_connection_string = var.application_insights_connection_string
    health_check_path                      = var.health_check_path
    health_check_eviction_time_in_min      = var.health_check_eviction_time_in_min

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        dotnet_version              = application_stack.value.dotnet_version
        use_dotnet_isolated_runtime = application_stack.value.use_dotnet_isolated_runtime
        java_version                = application_stack.value.java_version
        node_version                = application_stack.value.node_version
        python_version              = application_stack.value.python_version
        powershell_core_version     = application_stack.value.powershell_core_version
        use_custom_runtime          = application_stack.value.use_custom_runtime
      }
    }

    dynamic "cors" {
      for_each = var.cors != null ? [var.cors] : []
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = cors.value.support_credentials
      }
    }

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        name                      = ip_restriction.value.name
        action                    = ip_restriction.value.action
        ip_address                = ip_restriction.value.ip_address
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
        service_tag               = ip_restriction.value.service_tag
        priority                  = ip_restriction.value.priority
        headers                   = ip_restriction.value.headers
      }
    }
  }

  app_settings = merge(
    {
      "WEBSITE_RUN_FROM_PACKAGE" = var.run_from_package ? "1" : "0"
      "FUNCTIONS_WORKER_RUNTIME" = var.functions_worker_runtime
    },
    var.identity_type != "None" ? {
      "AZURE_CLIENT_ID" = var.azure_client_id
    } : {},
    var.app_settings
  )

  dynamic "sticky_settings" {
    for_each = length(var.sticky_app_setting_names) > 0 || length(var.sticky_connection_string_names) > 0 ? [1] : []
    content {
      app_setting_names       = var.sticky_app_setting_names
      connection_string_names = var.sticky_connection_string_names
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Windows Function App
# -----------------------------------------------------------------------------

resource "azurerm_windows_function_app" "this" {
  count = var.os_type == "Windows" ? 1 : 0

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  service_plan_id            = var.create_service_plan ? azurerm_service_plan.this[0].id : var.service_plan_id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_uses_managed_identity ? null : var.storage_account_access_key
  storage_uses_managed_identity = var.storage_uses_managed_identity

  # Security
  https_only                     = true
  public_network_access_enabled  = var.public_network_access_enabled
  key_vault_reference_identity_id = var.key_vault_reference_identity_id

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != "None" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # VNet Integration
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  site_config {
    always_on                              = var.sku_name != "Y1" ? var.always_on : false
    http2_enabled                          = var.http2_enabled
    minimum_tls_version                    = var.minimum_tls_version
    ftps_state                             = var.ftps_state
    vnet_route_all_enabled                 = var.vnet_route_all_enabled
    application_insights_key               = var.application_insights_key
    application_insights_connection_string = var.application_insights_connection_string
    health_check_path                      = var.health_check_path
    health_check_eviction_time_in_min      = var.health_check_eviction_time_in_min

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        dotnet_version              = application_stack.value.dotnet_version
        use_dotnet_isolated_runtime = application_stack.value.use_dotnet_isolated_runtime
        java_version                = application_stack.value.java_version
        node_version                = application_stack.value.node_version
        powershell_core_version     = application_stack.value.powershell_core_version
        use_custom_runtime          = application_stack.value.use_custom_runtime
      }
    }

    dynamic "cors" {
      for_each = var.cors != null ? [var.cors] : []
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = cors.value.support_credentials
      }
    }

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        name                      = ip_restriction.value.name
        action                    = ip_restriction.value.action
        ip_address                = ip_restriction.value.ip_address
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
        service_tag               = ip_restriction.value.service_tag
        priority                  = ip_restriction.value.priority
        headers                   = ip_restriction.value.headers
      }
    }
  }

  app_settings = merge(
    {
      "WEBSITE_RUN_FROM_PACKAGE" = var.run_from_package ? "1" : "0"
      "FUNCTIONS_WORKER_RUNTIME" = var.functions_worker_runtime
    },
    var.identity_type != "None" ? {
      "AZURE_CLIENT_ID" = var.azure_client_id
    } : {},
    var.app_settings
  )

  dynamic "sticky_settings" {
    for_each = length(var.sticky_app_setting_names) > 0 || length(var.sticky_connection_string_names) > 0 ? [1] : []
    content {
      app_setting_names       = var.sticky_app_setting_names
      connection_string_names = var.sticky_connection_string_names
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Private Endpoint
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = var.os_type == "Linux" ? azurerm_linux_function_app.this[0].id : azurerm_windows_function_app.this[0].id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}
