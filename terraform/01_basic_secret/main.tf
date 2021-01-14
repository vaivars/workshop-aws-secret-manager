provider "aws" {
}

resource "aws_secretsmanager_secret" "testvariable" {
  name = "testvariable"
}

resource "aws_secretsmanager_secret_version" "testvariable" {
  secret_id     = aws_secretsmanager_secret.testvariable.id
  secret_string = "aws-secrets-manager"
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "testvariable_generated" {
  name = "testvariable_generated"
}

resource "aws_secretsmanager_secret_version" "testvariable_generated" {
  secret_id     = aws_secretsmanager_secret.testvariable_generated.id
  secret_string = random_password.password.result
}