terraform {
  required_version = ">= 1.16, < 2.0"

  backend "azurerm" {
    use_cli              = true
    use_azuread_auth     = true
    resource_group_name  = "rg-portfolio-tfstate"
    storage_account_name = "sttfportfoliomg26"
    container_name       = "tfstate"
    key                  = "bootstrap.terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.6"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.6"
    }
  }
}