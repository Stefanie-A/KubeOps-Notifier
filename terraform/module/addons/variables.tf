variable "cluster_name"     { type = string }
variable "cluster_endpoint" { type = string }
variable "cluster_ca"       { type = string }
variable "app_of_apps_path" {
  type    = string
  default = "../k8s/argocd/app-of-apps.yaml"
}
