resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  # To expose Argo CD API server with an external IP
  set = [
    {
      name  = "server.service.type"
      value = "LoadBalancer"
    }
  ]
}