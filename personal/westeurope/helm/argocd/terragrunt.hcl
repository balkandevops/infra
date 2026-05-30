include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "helm_root" {
  path   = find_in_parent_folders("helm_root.hcl")
}

inputs = {

  name  = "argocd"
  chart = "argo-cd"
  repository = "oci://ghcr.io/argoproj/argo-helm"
  chart_version = "9.4.4"
  namespace     = "argocd"
  create_namespace = true
  wait = true
  atomic = true
  cleanup_on_fail = true
  
}

generate "main" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "name"  { type = string }
variable "chart" { type = string }
variable "repository" { type = string }
variable "chart_version" { type = string }
variable "namespace" { type = string }
variable "create_namespace" { type = bool }
variable "wait" { type = bool }
variable "atomic" { type = bool }
variable "cleanup_on_fail" { type = bool }
resource "helm_release" "this" {
  name             = var.name
  chart            = var.chart
  repository       = var.repository
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace
  wait             = var.wait
  atomic           = var.atomic
  cleanup_on_fail  = var.cleanup_on_fail
}
EOF
}
