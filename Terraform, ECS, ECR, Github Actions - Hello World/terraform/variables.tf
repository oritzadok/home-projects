variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "my-app"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "app_version" {
  type    = string
  default = "1.0.0"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "SuperSecretPassword123!"
}