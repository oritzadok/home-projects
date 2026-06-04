output "aws_region" {
  value = var.aws_region
}

output "eks_cluster" {
  value = aws_eks_cluster.cluster.name
}

output "ecr_repository_uri" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

#output "app_url" {
#  value = "http://${data.kubernetes_ingress_v1.ingress.status.0.load_balancer.0.ingress.0.hostname}"
#}