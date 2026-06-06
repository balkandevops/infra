include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "helm_root" {
  path   = find_in_parent_folders("helm_root.hcl")
}

dependency "eso_keyvault_workload" {
  config_path = "../../kubernetes/eso_keyvault_workload"
  mock_outputs = {
    client_id = "f47ac10b-58cc-4372-a567-0e02b2c3d479"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  name             = "external-secrets"
  chart            = "external-secrets"
  repository       = "oci://ghcr.io/external-secrets/charts"
  chart_version    = "2.0.1"
  namespace        = "external-secrets"
  create_namespace = true
  wait             = false
  atomic           = false
  cleanup_on_fail  = false
  timeout          = 600
  values_yaml      = [<<-YAML
  serviceAccount:
    create: true
    name: "external-secrets"
    annotations:
      azure.workload.identity/client-id: ${dependency.eso_keyvault_workload.outputs.client_id}
  podLabels:
    azure.workload.identity/use: "true"
  YAML
  ]
}

generate "main" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "name"             { type = string }
variable "chart"            { type = string }
variable "repository"       { type = string }
variable "chart_version"    { type = string }
variable "namespace"        { type = string }
variable "create_namespace" { type = bool }
variable "wait"             { type = bool }
variable "atomic"           { type = bool }
variable "cleanup_on_fail"  { type = bool }
variable "timeout"          { type = number }
variable "values_yaml"      { type = list(string) }

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
  timeout          = var.timeout
  values           = var.values_yaml
}
EOF
}
