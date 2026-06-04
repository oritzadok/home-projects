resource "kubernetes_manifest" "argocd_app" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "my-app"
      "namespace" = "argocd"
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "repoURL"        = var.git_repo
        "targetRevision" = "HEAD"
        "path"           = "helm"
        "helm"           = {
          # Parameters are specified here for simplicity.
          # In real world - use values file
          "parameters" = [
            {
              "name"  = "image.repository"
              "value" = "${var.acr_repo}"
            },
            {
              "name"  = "image.tag"
              "value" = "latest"
            },
            {
              "name"  = "resources.requests.cpu"
              "value" = "10m"
            },    
            {
              "name"  = "resources.requests.memory"
              "value" = "64Mi"
            }, 
            {
              "name"  = "resources.limits.cpu"
              "value" = "50m"
            },
            {
              "name"  = "resources.limits.memory"
              "value" = "128Mi"
            },
            {
              "name"  = "autoscaling.kedaManagedIdentityId"
              "value" = "${var.keda_managed_identity}"
            },
            {
              "name"  = "autoscaling.messageCount"
              "value" = "10"
            },
            {
              "name"  = "serviceAccount.name"
              "value" = "consumer"
            },
            {
              "name"  = "serviceAccount.managedIdentityId"
              "value" = "${var.consumer_managed_identity}"
            },
            {
              "name"  = "serviceBus.namespace"
              "value" = "${var.service_bus_namespace}"
            },
            {
              "name"  = "storageAccount.name"
              "value" = "${var.storage_account}"
            },
          ]
        }
      }
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = var.namespace
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
}