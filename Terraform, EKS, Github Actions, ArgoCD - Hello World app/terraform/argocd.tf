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

  depends_on = [
    aws_eks_node_group.node_group
  ]
}


resource "kubernetes_manifest" "argocd_app" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "hello-app"
      "namespace" = "argocd"
      #"finalizers" = [
      #  "resources-finalizer.argocd.argoproj.io"  # To delete k8s resources upon application deletion
      #]
    }
    "spec" = {
      "project" = "default"
      "sources" = [
        {
          "repoURL"        = "https://github.com/${var.gh_repo}.git"
          "targetRevision" = "HEAD"
          "path"           = "helm"
          "helm"           = {
            "releaseName" = "hello-app"
            "valueFiles"  = [
              "$values/helm_values.yaml"
            ]
          }
        },
        # Second source is for the actual Helm values files to apply at installation.
        # ( https://argo-cd.readthedocs.io/en/stable/user-guide/helm/#values-files
        # https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/#helm-value-files-from-external-git-repository )
        # For simplicity it's same repository, but a better practice is store them in a separated GitOps repository
        {
          "repoURL"        = "https://github.com/${var.gh_repo}.git"
          "targetRevision" = "HEAD"
          "ref"            = "values"
        }
      ]
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = "hello-app"
      }
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
        "syncOptions" = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [
    helm_release.argocd,
    null_resource.run_first_build
  ] 
}


## To get ALB address
#data "kubernetes_ingress_v1" "ingress" {
#  metadata {
#    name      = "hello-app"
#    namespace = "hello-app"
#  }
#
#  depends_on = [
#    kubernetes_manifest.argocd_app
#  ] 
#}