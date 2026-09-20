terraform {
  backend "azurerm" {
    resource_group_name  = "rg-10alytics-devops"
    storage_account_name = "st10alyticstfstate"
    container_name       = "tfstate"
    key                  = "10alytics.tfstate"
    use_azuread_auth     = true
  }
}