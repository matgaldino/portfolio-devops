terraform {
  required_version = ">= 1.16, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.6"
    }
  }

  backend "azurerm" {
    use_cli              = true
    use_azuread_auth     = true
    resource_group_name  = "rg-portfolio-tfstate"
    storage_account_name = "sttfportfoliomg26"
    container_name       = "tfstate"
    key                  = "portfolio.terraform.tfstate"
  }
}