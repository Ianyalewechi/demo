output "resource_group_name" {
  description = "Azure resource group name"
  value       = data.azurerm_resource_group.main.name
}

output "location" {
  description = "Azure resource location"
  value       = data.azurerm_resource_group.main.location
}

output "vm_name" {
  description = "Azure VM name"
  value       = azurerm_linux_virtual_machine.main.name
}

output "vm_public_ip" {
  description = "Azure VM public IP address"
  value       = azurerm_public_ip.main.ip_address
}

output "application_url" {
  description = "Application URL"
  value       = "http://${azurerm_public_ip.main.ip_address}"
}

output "health_url" {
  description = "Application health endpoint"
  value       = "http://${azurerm_public_ip.main.ip_address}/health"
}

output "readiness_url" {
  description = "Application readiness endpoint"
  value       = "http://${azurerm_public_ip.main.ip_address}/health/ready"
}

output "acr_name" {
  description = "Azure Container Registry name"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Azure Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "key_vault_name" {
  description = "Azure Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "github_actions_client_id" {
  description = "Client ID of the GitHub Actions managed identity"
  value       = data.azurerm_user_assigned_identity.github_actions.client_id
}

output "github_actions_principal_id" {
  description = "Principal ID of the GitHub Actions managed identity"
  value       = data.azurerm_user_assigned_identity.github_actions.principal_id
}

output "vm_identity_client_id" {
  description = "Client ID of the VM managed identity"
  value       = azurerm_user_assigned_identity.vm.client_id
}

output "vm_identity_principal_id" {
  description = "Principal ID of the VM managed identity"
  value       = azurerm_user_assigned_identity.vm.principal_id
}