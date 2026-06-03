# Ingress controller
resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set = [
    {
      name  = "region"
      value = var.aws_region
    },
    {
      name  = "vpcId"
      value = aws_vpc.vpc.id
    },
    {
      name  = "clusterName"
      value = aws_eks_cluster.cluster.name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.alb_controller.arn
    }
  ]

  depends_on = [
    aws_eks_node_group.node_group,
    aws_eks_addon.cloudwatch_observability
  ]
}


# Faster and cheaper than default created "gp2" StorageClass.
# Will be for postgres pod persistence in the wiki.js Helm chart
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }
  volume_binding_mode = "WaitForFirstConsumer"
}


resource "helm_release" "wiki" {
  name       = "wiki"
  repository = "https://charts.js.wiki"
  chart      = "wiki"
  namespace  = "wiki"
  create_namespace = true

  values = [
    templatefile("files/wiki_helm_values.yaml.tfpl", {
      acm_cert_arn = aws_acm_certificate.wiki_internal.arn
    })
  ]

  depends_on = [
    kubernetes_storage_class.gp3,
    helm_release.aws_lb_controller
  ]
}