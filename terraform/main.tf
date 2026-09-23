resource "azurerm_resource_group" "portfolio" {
  name     = "rg-portfolio-devops"
  location = "France Central"
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
  name                       = "cae-portfolio-devops"
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
      image  = "acrportfolio2026mg.azurecr.io/portfolio-devops:cbe2076501156af7d2d697a482d89f44a3485553"
      cpu    = 0.5
      memory = "1.0Gi"
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