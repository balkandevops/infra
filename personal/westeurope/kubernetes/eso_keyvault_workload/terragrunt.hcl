include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  prefix   = include.root.locals.prefix
  location = include.root.locals.location
  tags     = include.root.locals.default_tags
}

dependency "resource_group" {
  config_path = "../../resource_group"
  mock_outputs = {
    name = "mock-rg"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "key_vault" {
  config_path = "../key_vault"
  mock_outputs = {
    id = "/subscriptions/abd13184-ef5f-4226-83e4-12d6fbacc980/resourceGroups/mock-rg/providers/Microsoft.KeyVault/vaults/mock-kv"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "kubernetes_cluster" {
  config_path = "../kubernetes_cluster"
  mock_outputs = {
    oidc_issuer_url = "https://westeurope.oic.prod-aks.azure.com/mock-tenant/mock-oidc/"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  name                = "eso-workload-${local.prefix}"
  location            = local.location
  resource_group_name = dependency.resource_group.outputs.name
  key_vault_id        = dependency.key_vault.outputs.id
  oidc_issuer_url     = dependency.kubernetes_cluster.outputs.oidc_issuer_url
  tags                = local.tags
}

generate "main" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "name"                { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "key_vault_id"        { type = string }
variable "oidc_issuer_url"     { type = string }
variable "tags"                { type = map(string) }

resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_federated_identity_credential" "eso" {
  name                = "eso-federated-credential"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.this.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:external-secrets:external-secrets"
}

output "client_id"    { value = azurerm_user_assigned_identity.this.client_id }
output "principal_id" { value = azurerm_user_assigned_identity.this.principal_id }
EOF
}
