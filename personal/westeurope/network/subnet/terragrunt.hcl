include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  prefix = include.root.locals.prefix
}

dependency "resource_group" {
  config_path = "../../resource_group"
  mock_outputs = {
    name = "mock-rg"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "vnet" {
  config_path = "../vnet"
  mock_outputs = {
    name = "mock-vnet"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  name                 = "snet-k8s-${local.prefix}"
  resource_group_name  = dependency.resource_group.outputs.name
  virtual_network_name = dependency.vnet.outputs.name
  address_prefixes     = ["10.240.0.0/16"]
}

generate "main" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "name"                 { type = string }
variable "resource_group_name"  { type = string }
variable "virtual_network_name" { type = string }
variable "address_prefixes"     { type = list(string) }

resource "azurerm_subnet" "this" {
  name                 = var.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.address_prefixes
}

output "id"   { value = azurerm_subnet.this.id }
output "name" { value = azurerm_subnet.this.name }
EOF
}
