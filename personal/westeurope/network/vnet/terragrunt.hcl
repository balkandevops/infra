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
  name                = "vnet-${local.prefix}"
  location            = local.location
  resource_group_name = dependency.resource_group.outputs.name
  address_space       = ["10.0.0.0/8"]
  tags                = local.tags
}

generate "main" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "name"                { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "address_space"       { type = list(string) }
variable "tags"                { type = map(string) }

resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

output "id"   { value = azurerm_virtual_network.this.id }
output "name" { value = azurerm_virtual_network.this.name }
EOF
}
