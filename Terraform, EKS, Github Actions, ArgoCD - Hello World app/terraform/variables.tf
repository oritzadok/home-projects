variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "env_name" {
  description = "A prefix to identify the environment (e.g. your name)"
  type        = string
  default     = "ori"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for EKS cluster worker nodes"
}

variable "gh_repo" {
  type        = string
  description = "Github repository for Github Actions CI/CD, in the form of org/repo"
}