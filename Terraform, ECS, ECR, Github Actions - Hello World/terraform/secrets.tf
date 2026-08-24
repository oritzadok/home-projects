resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "${var.project_name}/database/credentials"
  description             = "${var.project_name} database credentials managed by Terraform"
  recovery_window_in_days = 7 # Set to 0 to force delete immediately during testing
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    # username = "admin_user"
    password = var.db_password
  })
}

# Can skip this, but simulating a situation where the secret is created in another Terraform module or manually
data "aws_secretsmanager_secret" "db_secret" {
  name = "${var.project_name}/database/credentials"

  # Only needed when creating the secret in the same Terraform module
  depends_on = [aws_secretsmanager_secret_version.db_secret_val]
}