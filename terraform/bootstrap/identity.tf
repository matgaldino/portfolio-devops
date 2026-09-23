resource "azuread_application_registration" "terraform_plan" {
  display_name                   = "github-portfolio-terraform-plan"
  requested_access_token_version = 2
}

resource "azuread_service_principal" "terraform_plan" {
  client_id = azuread_application_registration.terraform_plan.client_id
}

resource "azuread_application_federated_identity_credential" "terraform_plan_pr" {
  application_id = azuread_application_registration.terraform_plan.id
  display_name   = "github-pr"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:matgaldino@95775755/portfolio-devops@1379996565:pull_request"
}

resource "azuread_application_registration" "deploy" {
  display_name                   = "github-portfolio-devops"
  requested_access_token_version = 2
}

resource "azuread_service_principal" "deploy" {
  client_id = azuread_application_registration.deploy.client_id
}

resource "azuread_application_federated_identity_credential" "deploy_main" {
  application_id = azuread_application_registration.deploy.id
  display_name   = "github-main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:matgaldino@95775755/portfolio-devops@1379996565:ref:refs/heads/main"
}

resource "azuread_application_registration" "terraform_apply" {
  display_name                   = "github-portfolio-terraform-apply"
  requested_access_token_version = 2
}

resource "azuread_service_principal" "terraform_apply" {
  client_id = azuread_application_registration.terraform_apply.client_id
}

resource "azuread_application_federated_identity_credential" "terraform_apply_production" {
  application_id = azuread_application_registration.terraform_apply.id
  display_name   = "github-production"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:matgaldino@95775755/portfolio-devops@1379996565:environment:production"
}