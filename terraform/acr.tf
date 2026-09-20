resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  sku           = "Basic"
  admin_enabled = false

  tags = {
    Project = "10Alytics DevOps Assessment"
  }
}

resource "azurerm_role_assignment" "github_acr_push" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_user_assigned_identity.github_actions.principal_id

  lifecycle {
    ignore_changes = [
      role_definition_id,
      principal_type
    ]
  }
}

resource "azurerm_role_assignment" "vm_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
}