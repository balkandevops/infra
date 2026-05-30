locals {
  subscription_id              = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals.subscription_id
  environment                  = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals.environment
  location                     = read_terragrunt_config(find_in_parent_folders("location.hcl")).locals.location
  project                      = "balkandevops"

  prefix                       = "${local.project}-${local.environment}"

  default_tags = {
    Project     = local.project
    Environment = local.environment
    Managed_by  = "Terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "azurerm" {
  features {}
  subscription_id = "${local.subscription_id}"
}
EOF
}

remote_state {
  backend = "azurerm"
  config = {
    subscription_id      = local.subscription_id
    resource_group_name  = "rg-${local.project}-tfstate"
    storage_account_name = "${local.project}tfstate"
    container_name       = "${local.project}tfstate"
    key                  = "${path_relative_to_include()}/tf.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
