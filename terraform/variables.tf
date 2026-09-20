
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID"
  type        = string
}

variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = "rg-10alytics-devops"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "acr_name" {
  description = "Globally unique Azure Container Registry name"
  type        = string
}

variable "vm_name" {
  description = "Azure VM name"
  type        = string
  default     = "vm-10alytics"
}

variable "key_vault_name" {
  description = "Globally unique Azure Key Vault name"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in the format owner/repository"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch trusted by Azure OIDC"
  type        = string
  default     = "main"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Linux VM administrator username"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key used to access the Linux VM"
  type        = string
  sensitive   = true
}

variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Subnet address prefixes"
  type        = list(string)
  default     = ["10.10.1.0/24"]
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to access SSH. Replace with your trusted public IP CIDR."
  type        = string
  default     = "0.0.0.0/0"
}

