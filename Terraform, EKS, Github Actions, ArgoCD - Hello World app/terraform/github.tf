resource "aws_ecr_repository" "ecr_repo" {
  name                 = "${var.env_name}-repo"
  image_tag_mutability = "MUTABLE"  # default

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
}

# For Github Actions access
resource "aws_iam_openid_connect_provider" "gh_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]

  tags = { 
    Name = "${var.env_name}-gh_actions"
  }
}


# Used by Github Actions workflows
resource "aws_iam_role" "gh_actions" {
  name               = "${var.env_name}-gh_actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "${aws_iam_openid_connect_provider.gh_actions.arn}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = [
              "sts.amazonaws.com"
            ] 
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.gh_repo}:*"
            ]
          }
        }
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "gh_role" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.gh_actions.name
}


locals {
  repo_name = split("/", var.gh_repo)[1]
}


resource "github_actions_secret" "aws_role_arn" {
  repository      = local.repo_name
  secret_name     = "AWS_ROLE_ARN"
  plaintext_value = aws_iam_role.gh_actions.arn
}


resource "github_actions_secret" "ecr_repo_url" {
  repository      = local.repo_name
  secret_name     = "ECR_REPOSITORY_URI"
  plaintext_value = aws_ecr_repository.ecr_repo.repository_url
}


resource "github_actions_variable" "aws_region" {
  repository    = local.repo_name
  variable_name = "AWS_REGION"
  value         = var.aws_region
}


# Initially, when the created ECR repository is empty, need to build an image before deploying the application
resource "null_resource" "run_first_build" {
  provisioner "local-exec" {
    command = "./files/run_first_build.sh ${aws_ecr_repository.ecr_repo.name} ${var.gh_repo}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.gh_role
  ]
}
