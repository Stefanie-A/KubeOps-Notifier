resource "null_resource" "helm_repo_update" {
  provisioner "local-exec" {
    command = "helm repo add argoproj https://argoproj.github.io/argo-helm && helm repo update"
  }
}

resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = "aws eks wait cluster-active --name ${var.cluster_name} && sleep 30"
  }
}

resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region us-east-1 --name ${var.cluster_name}"
  }
  
  depends_on = [null_resource.wait_for_cluster]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "6.7.3"
  namespace        = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      configs = {
        params = {
          server = {
            insecure = true
          }
        }
      }
    })
  ]

  depends_on = [null_resource.helm_repo_update, null_resource.update_kubeconfig]
}

# Bootstrap the App-of-Apps after ArgoCD is ready
resource "kubectl_manifest" "app_of_apps" {
  yaml_body  = file(var.app_of_apps_path)
  depends_on = [helm_release.argocd]
}
