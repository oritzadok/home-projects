output "aws_region" {
  value = var.aws_region
}

output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "The VPC where the Wiki.js app is accessible"
}

output "app_url" {
  value       = "https://${aws_route53_record.wiki.name}"
  description = "The URL of the Wiki.js app"
}

output "eks_cluster" {
  value       = aws_eks_cluster.cluster.name
  description = "The AWS EKS cluster where the Wiki.js app is hosted"
}

output "wiki_helm_release" {
  value = helm_release.wiki.name
}

output "namespace" {
  value       = helm_release.wiki.namespace
  description = "The Kubernetes namespace where the Wiki.js app is deployed"
}