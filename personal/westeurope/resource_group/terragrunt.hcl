include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  prefix   = include.root.locals.prefix
  location = include.root.locals.location
  tags     = include.root.locals.default_tags
}

inputs = {
  name     = "rg-${local.prefix}"
  location = local.location
  tags     = local.tags
}

generate "main" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "name"     { type = string }
variable "location" { type = string }
variable "tags"     { type = map(string) }

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}

output "name"     { value = azurerm_resource_group.this.name }
output "location" { value = azurerm_resource_group.this.location }
EOF
}
