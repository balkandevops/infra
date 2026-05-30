dependency "kubernetes_cluster" {
  config_path = "../../kubernetes/kubernetes_cluster"
  mock_outputs = {
    kube_config   = "Mock file content"
    cluster_name  = "MockClusterName"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

generate "kubeconfig" {
  path      = "kubeconfig-${dependency.kubernetes_cluster.outputs.cluster_name}"
  contents  = replace(dependency.kubernetes_cluster.outputs.kube_config, "- devicecode", "- azurecli") 
  if_exists = "overwrite"
}
  
  generate "helmprovider" {
  path      = "helmprovider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
    provider "helm" {
      kubernetes = {
        config_path = "kubeconfig-${dependency.kubernetes_cluster.outputs.cluster_name}"
      }
    }
  EOF
}