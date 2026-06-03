variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "env_name" {
  description = "Identifier name of the environment"
  type        = string
  default     = "ori"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/18"
}

variable "azs" {
  type    = list(string)
  default = ["a", "b", "c"]
}

variable "public_subnet_cidrs" {
  description = "One CIDR block for each az in azs"
  type        = list(string)
  default     = [
    "10.0.0.0/24",
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnet_cidrs" {
  description = "One CIDR block for each az in azs"
  type        = list(string)
  default     = [
    "10.0.16.0/24",
    "10.0.17.0/24",
    "10.0.18.0/24"
  ]
}