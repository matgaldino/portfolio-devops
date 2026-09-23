data "azurerm_storage_account" "tfstate" {
  name                = "sttfportfoliomg26"
  resource_group_name = "rg-portfolio-tfstate"
}

locals {
  tfstate_container_scope = "${data.azurerm_storage_account.tfstate.id}/blobServices/default/containers/tfstate"
}

resource "azurerm_storage_container" "tfplans" {
  name                  = "tfplans"
  storage_account_id    = data.azurerm_storage_account.tfstate.id
  container_access_type = "private"
}