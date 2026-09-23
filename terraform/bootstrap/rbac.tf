data "azurerm_resource_group" "portfolio" {
  name = "rg-portfolio-devops"
}

resource "azurerm_role_definition" "terraform_plan_containerapp" {
  name        = "Terraform Container App Plan Reader"
  scope       = data.azurerm_resource_group.portfolio.id
  description = "Allows Terraform plan to read Container App secrets during refresh."

  permissions {
    actions = [
      "Microsoft.App/containerApps/listSecrets/action",
    ]

    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_resource_group.portfolio.id,
  ]
}

resource "azurerm_role_assignment" "terraform_plan_reader" {
  scope                = data.azurerm_resource_group.portfolio.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.terraform_plan.object_id
}

resource "azurerm_role_assignment" "terraform_plan_tfstate" {
  scope                = local.tfstate_container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.terraform_plan.object_id
}

data "azurerm_container_app" "portfolio" {
  name                = "portfolio-devops"
  resource_group_name = data.azurerm_resource_group.portfolio.name
  read_secrets        = false
}

resource "azurerm_role_assignment" "terraform_plan_containerapp" {
  scope = replace(
    data.azurerm_container_app.portfolio.id,
    "containerApps",
    "containerapps"
  )

  role_definition_id = azurerm_role_definition.terraform_plan_containerapp.role_definition_resource_id
  principal_id       = azuread_service_principal.terraform_plan.object_id
}

data "azurerm_container_registry" "portfolio" {
  name                = "acrportfolio2026mg"
  resource_group_name = data.azurerm_resource_group.portfolio.name
}

resource "azurerm_role_assignment" "deploy_acr_push" {
  scope                = data.azurerm_container_registry.portfolio.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.deploy.object_id
}

resource "azurerm_role_assignment" "deploy_containerapp_contributor" {
  scope = replace(
    data.azurerm_container_app.portfolio.id,
    "containerApps",
    "containerapps"
  )

  role_definition_name = "Container Apps Contributor"
  principal_id         = azuread_service_principal.deploy.object_id
}

resource "azurerm_role_assignment" "terraform_apply_contributor" {
  scope                = data.azurerm_resource_group.portfolio.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.terraform_apply.object_id
}

resource "azurerm_role_assignment" "terraform_apply_tfstate" {
  scope                = local.tfstate_container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.terraform_apply.object_id
}

resource "azurerm_role_assignment" "terraform_apply_acr_rbac" {
  scope                = data.azurerm_container_registry.portfolio.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azuread_service_principal.terraform_apply.object_id
}

resource "azurerm_role_assignment" "terraform_plan_tfplans" {
  scope                = azurerm_storage_container.tfplans.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.terraform_plan.object_id
}

resource "azurerm_role_assignment" "terraform_apply_tfplans" {
  scope                = azurerm_storage_container.tfplans.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.terraform_apply.object_id
}