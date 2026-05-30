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
    name     = "mock-rg"
    location = "westeurope"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  name                 = "kv-${local.prefix}"
  location             = local.location
  resource_group_name  = dependency.resource_group.outputs.name
  tags                 = local.tags
}



generate "main" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "name"                 { type = string }
variable "location"             { type = string }
variable "resource_group_name"  { type = string }
variable "tags"                 { type = map(string) }

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  enable_rbac_authorization  = true
  tags                       = var.tags
}

output "id"   { value = azurerm_key_vault.this.id }
output "name" { value = azurerm_key_vault.this.name }
output "uri"  { value = azurerm_key_vault.this.vault_uri }
EOF
}