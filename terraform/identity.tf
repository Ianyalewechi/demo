#
# Existing GitHub Actions managed identity
#

data "azurerm_user_assigned_identity" "github_actions" {
  name                = "id-10alytics-github-actions"
  resource_group_name = data.azurerm_resource_group.main.name
}

#
# VM managed identity
#

resource "azurerm_user_assigned_identity" "vm" {
  name                = "id-10alytics-vm"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Project = "10Alytics DevOps Assessment"
    Purpose = "Azure VM"
  }
}