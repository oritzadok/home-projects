# IAM OIDC provider, used for IRSA
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]

  tags = { 
    Name = "${var.env_name}-eks-irsa"
  }
}


resource "aws_eks_addon" "metrics_server" {
  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "metrics-server"
  addon_version = "v0.8.0-eksbuild.2"

  depends_on = [
    aws_eks_node_group.node_group
  ]
}


resource "aws_iam_role" "cloudwatch_observability" {
  name               = "${var.env_name}-cloudwatch-observability-role"
  assume_role_policy = templatefile("files/eks_role_assume_policy.json.tfpl", {
    oidc_arn     = aws_iam_openid_connect_provider.eks.arn
    oidc_url     = aws_iam_openid_connect_provider.eks.url
    sa_namespace = "amazon-cloudwatch"
    sa_name      = "cloudwatch-agent"
  })
}


resource "aws_iam_role_policy_attachment" "cloudwatch_observability" {
  role       = aws_iam_role.cloudwatch_observability.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


# Installs CloudWatch Agent and enables Container Insights
# and Application Signals for cluster health and performance observability
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "amazon-cloudwatch-observability"
  addon_version            = "v4.4.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.cloudwatch_observability.arn

  depends_on = [
    aws_eks_node_group.node_group
  ]
}


# For AWS Load Balancer Controller
resource "aws_iam_role" "alb_controller" {
  name               = "${var.env_name}-alb-controller-role"
  assume_role_policy = templatefile("files/eks_role_assume_policy.json.tfpl", {
    oidc_arn     = aws_iam_openid_connect_provider.eks.arn
    oidc_url     = aws_iam_openid_connect_provider.eks.url
    sa_namespace = "kube-system"
    sa_name      = "aws-load-balancer-controller"
  })
}


resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("files/alb_controller_iam_policy.json")
}


resource "aws_iam_role_policy_attachment" "alb_controller" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}


# To determine VPC ID
data "aws_subnet" "subnet1" {
  id = var.subnet_ids[0]
}


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
      value = data.aws_subnet.subnet1.vpc_id
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
    aws_iam_role_policy_attachment.alb_controller,
    aws_eks_addon.cloudwatch_observability
  ]
}