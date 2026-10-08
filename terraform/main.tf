resource "azurerm_resource_group" "portfolio" {
  name     = "rg-portfolio-devops"
  location = "France Central"

  tags = {
    project     = "portfolio-devops"
    environment = "production"
    managed_by  = "terraform"
  }
}

resource "azurerm_container_registry" "portfolio" {
  name                = "acrportfolio2026mg"
  resource_group_name = azurerm_resource_group.portfolio.name
  location            = azurerm_resource_group.portfolio.location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "azurerm_user_assigned_identity" "containerapp" {
  name                = "id-portfolio-containerapp"
  resource_group_name = azurerm_resource_group.portfolio.name
  location            = azurerm_resource_group.portfolio.location
}

resource "azurerm_role_assignment" "containerapp_acr_pull" {
  scope                = azurerm_container_registry.portfolio.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.containerapp.principal_id
}

resource "azurerm_log_analytics_workspace" "portfolio" {
  name                         = "workspace-rgportfoliodevopsRigD"
  resource_group_name          = azurerm_resource_group.portfolio.name
  location                     = azurerm_resource_group.portfolio.location
  sku                          = "PerGB2018"
  retention_in_days            = 30
  local_authentication_enabled = true
}

resource "azurerm_container_app_environment" "portfolio" {
  name                       = "cae-portfolio-devops-standard"
  location                   = azurerm_resource_group.portfolio.location
  resource_group_name        = azurerm_resource_group.portfolio.name
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.portfolio.id
  public_network_access      = "Enabled"
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    minimum_count         = 0
    maximum_count         = 0
  }
}

resource "azurerm_container_app" "portfolio" {
  name                         = "portfolio-devops"
  container_app_environment_id = azurerm_container_app_environment.portfolio.id
  resource_group_name          = azurerm_resource_group.portfolio.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type = "UserAssigned"

    identity_ids = [
      azurerm_user_assigned_identity.containerapp.id
    ]
  }

  registry {
    server = azurerm_container_registry.portfolio.login_server

    identity = replace(
      azurerm_user_assigned_identity.containerapp.id,
      "resourceGroups",
      "resourcegroups"
    )
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = 80
    transport                  = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    http_scale_rule {
      name                = "http-scaler"
      concurrent_requests = 10
    }

    container {
      name   = "portfolio-devops"
      image  = "acrportfolio2026mg.azurecr.io/portfolio-devops@sha256:35c3ca84cfd6b1a8846eb6727e7a9b38360a9f150e3e5bc29ad7cc1eafed3f6f"
      cpu    = 0.5
      memory = "1Gi"
      liveness_probe {
        transport               = "HTTP"
        port                    = 80
        path                    = "/health"
        initial_delay           = 5
        interval_seconds        = 10
        timeout                 = 2
        failure_count_threshold = 3
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      ingress[0].traffic_weight,
      template[0].cooldown_period_in_seconds,
      template[0].polling_interval_in_seconds,
    ]
  }
}

resource "azapi_resource_action" "container_app_environment_mode" {
  type        = "Microsoft.App/managedEnvironments@2025-10-02-preview"
  resource_id = azurerm_container_app_environment.portfolio.id
  method      = "PATCH"

  body = {
    properties = {
      environmentMode = "WorkloadProfiles"
    }
  }
}

resource "azurerm_monitor_metric_alert" "container_restart" {
  name                = "portfolio-container-restarts"
  resource_group_name = azurerm_resource_group.portfolio.name
  scopes              = [azurerm_container_app.portfolio.id]

  description = "Alert when the portfolio Container App restarts."
  severity    = 2

  frequency   = "PT1M"
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "RestartCount"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.portfolio_alerts.id
  }
}

resource "azurerm_monitor_action_group" "portfolio_alerts" {
  name                = "portfolio-alerts"
  resource_group_name = azurerm_resource_group.portfolio.name
  short_name          = "portfolio"

  email_receiver {
    name                    = "owner"
    email_address           = "matheusgaldino2011@gmail.com"
    use_common_alert_schema = true
  }
}