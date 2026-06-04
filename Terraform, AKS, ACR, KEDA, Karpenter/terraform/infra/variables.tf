variable "resource_group_name" {
  default = "MyApp"
}

variable "resource_group_location" {
  default = "uksouth"
}

variable "storage_account_name" {
  default = "myapp1234"
}

variable "k8s_namespace" {
  description = "Kubernetes namespace within the AKS cluster to deploy the app"
  default     = "my-app"
}