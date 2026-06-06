include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "helm_root" {
  path   = find_in_parent_folders("helm_root.hcl")
}

dependencies {
  paths = ["../argocd", "../aks-private"]
}

inputs = {
  name            = "platform-base"
  chart           = "${get_terragrunt_dir()}/../charts/raw"
  chart_version   = "0.1.0"
  namespace       = "argocd"
  wait            = true
  atomic          = true
  cleanup_on_fail = true
  values_yaml     = [file("${get_terragrunt_dir()}/values.yaml")]
}

generate "main" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "name"            { type = string }
variable "chart"           { type = string }
variable "chart_version"   { type = string }
variable "namespace"       { type = string }
variable "wait"            { type = bool }
variable "atomic"          { type = bool }
variable "cleanup_on_fail" { type = bool }
variable "values_yaml"     { type = list(string) }

resource "helm_release" "this" {
  name            = var.name
  chart           = var.chart
  version         = var.chart_version
  namespace       = var.namespace
  wait            = var.wait
  atomic          = var.atomic
  cleanup_on_fail = var.cleanup_on_fail
  values          = var.values_yaml
}
EOF
}
