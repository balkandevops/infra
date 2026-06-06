include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "helm_root" {
  path   = find_in_parent_folders("helm_root.hcl")
}

locals {
  cluster_secret_store_name = "azure-keyvault-store"
  tenant_id                 = include.root.locals.subscription_id != "" ? "93004b47-238e-4ef7-b9f7-8085640be5b8" : ""
}

dependencies {
  paths = ["../eso"]
}

dependency "key_vault" {
  config_path = "../../kubernetes/key_vault"
  mock_outputs = {
    uri = "https://mock-kv.vault.azure.net/"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  name             = "aks-private"
  chart            = "${get_terragrunt_dir()}/../charts/raw"
  chart_version    = "0.1.0"
  namespace        = "external-secrets"
  create_namespace = false
  wait             = true
  atomic           = true
  cleanup_on_fail  = true
  values_yaml      = [<<-YAML
  extraObjects:
    - apiVersion: external-secrets.io/v1
      kind: ClusterSecretStore
      metadata:
        name: ${local.cluster_secret_store_name}
      spec:
        provider:
          azurekv:
            tenantId: "93004b47-238e-4ef7-b9f7-8085640be5b8"
            vaultUrl: ${dependency.key_vault.outputs.uri}
            authType: WorkloadIdentity
    - apiVersion: v1
      kind: Namespace
      metadata:
        name: cert-manager
    - apiVersion: external-secrets.io/v1
      kind: ExternalSecret
      metadata:
        name: cloudflare-api-token
        namespace: cert-manager
      spec:
        refreshInterval: 1h
        secretStoreRef:
          name: ${local.cluster_secret_store_name}
          kind: ClusterSecretStore
        target:
          name: cloudflare-api-token
        data:
          - secretKey: api-token
            remoteRef:
              key: cloudflare-api-token
    - apiVersion: v1
      kind: Namespace
      metadata:
        name: external-dns
    - apiVersion: external-secrets.io/v1
      kind: ExternalSecret
      metadata:
        name: cloudflare-api-token
        namespace: external-dns
      spec:
        refreshInterval: 1h
        secretStoreRef:
          name: ${local.cluster_secret_store_name}
          kind: ClusterSecretStore
        target:
          name: cloudflare-api-token
        data:
          - secretKey: cloudflare_api_token
            remoteRef:
              key: cloudflare-api-token
  YAML
  ]
}

generate "main" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "name"             { type = string }
variable "chart"            { type = string }
variable "chart_version"    { type = string }
variable "namespace"        { type = string }
variable "create_namespace" { type = bool }
variable "wait"             { type = bool }
variable "atomic"           { type = bool }
variable "cleanup_on_fail"  { type = bool }
variable "values_yaml"      { type = list(string) }

resource "helm_release" "this" {
  name             = var.name
  chart            = var.chart
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace
  wait             = var.wait
  atomic           = var.atomic
  cleanup_on_fail  = var.cleanup_on_fail
  values           = var.values_yaml
}
EOF
}
