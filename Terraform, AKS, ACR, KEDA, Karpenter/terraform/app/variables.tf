variable "git_repo" {
  description = "URL of this Git repository"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy the app"
  default     = "my-app"
}

variable "acr_repo" {}

variable "keda_managed_identity" {}

variable "consumer_managed_identity" {}

variable "service_bus_namespace" {}

variable "storage_account" {}