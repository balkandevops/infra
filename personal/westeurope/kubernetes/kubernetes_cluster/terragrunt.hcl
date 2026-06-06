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

dependency "subnet" {
  config_path = "../../network/subnet"
  mock_outputs = {
    id   = "/subscriptions/abd13184-ef5f-4226-83e4-12d6fbacc980/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-subnet"
    name = "mock-subnet-name"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}



inputs = {
  prefix              = local.prefix
  location            = local.location
  tags                = local.tags
  resource_group_name = dependency.resource_group.outputs.name
  vnet_subnet_id      = dependency.subnet.outputs.id
}



generate "main" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "prefix"   { type = string }
variable "location" { type = string }  
variable "tags"     { type = map(string) }
variable "vnet_subnet_id" { type = string }
variable "resource_group_name" { type = string }
resource "azurerm_kubernetes_cluster" "this" {
  name                = "k8s-$${var.prefix}"
  location            = var.location
  oidc_issuer_enabled = true
  workload_identity_enabled = true
  resource_group_name = var.resource_group_name
  dns_prefix          = "k8s-$${var.prefix}"
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B4s_v2"
    vnet_subnet_id = var.vnet_subnet_id
  }
  identity {
    type = "SystemAssigned"
  }


  tags = var.tags
}
output "id"              { value = azurerm_kubernetes_cluster.this.id }
output "cluster_name"   { value = azurerm_kubernetes_cluster.this.name }
output "oidc_issuer_url" { value = azurerm_kubernetes_cluster.this.oidc_issuer_url }
output "kube_config" {
  value = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive = true
}
EOF
}
