provider "aws" {
}

resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
}
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
    count = length(var.public_subnet)

    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet[count.index]
    availability_zone = var.availability_zones[count.index]
    tags = {
      Name = var.public_name[count.index]
    }
}

resource "aws_subnet" "private" {
    count = length(var.private_subnet)

    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet[count.index]
    availability_zone = var.availability_zones[count.index]

    tags = {
      Name = var.private_name[count.index]
    }
}

resource "aws_db_subnet_group" "main" {

  name       = "rds-group"
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_security_group" "rds" {
  name = "RDS"
  vpc_id = aws_vpc.main.id

  ingress  {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks  = ["10.100.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.public_cidr]
  }
}

module "db" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 3.0"

  name                            = "aurora-db-mysql"
  engine                          = "aurora-mysql"
  engine_version                  = "5.7.mysql_aurora.2.07.2"

  replica_scale_enabled           = false
  replica_count                   = 1
  skip_final_snapshot             = true

  vpc_id                          = aws_vpc.main.id
  subnets                         = aws_subnet.private.*.id
  allowed_security_groups         = [aws_security_group.rds.id]

  instance_type                   = "db.t3.small"
  storage_encrypted               = true
  apply_immediately               = true
  monitoring_interval             = 10


  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

}

resource "aws_secretsmanager_secret" "workshop_rds_root_password" {
  name = "workshop_rds_root_password"
}

resource "aws_secretsmanager_secret_version" "workshopname" {
  secret_id     = aws_secretsmanager_secret.workshop_rds_root_password.id
  secret_string = module.db.this_rds_cluster_master_password
}