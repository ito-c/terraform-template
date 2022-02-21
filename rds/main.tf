terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws = ">= 3.37.0"
  }
  backend "s3" {
    bucket = "tfstate-terraform-template"
    key    = "rds/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

#--------------------------------------------------
# Data only Modules
#--------------------------------------------------

module "network" {
  source = "./network"
}

#--------------------------------------------------
# Securiry Group
#--------------------------------------------------

# EC2にアタッチしているSG
data "aws_security_group" "ec2" {
  tags = {
    ProjectName  = "terraform_template"
    Environment  = "dev"
    ResourceName = "ec2"
  }
}

module "security_group_for_rds" {
  source = "../modules/security_group"
  vpc_id = module.network.vpc_id
  port   = "3306"

  is_specified_sg          = true
  source_security_group_id = data.aws_security_group.ec2.id

  environment   = var.environment
  project_name  = var.project_name
  resource_name = "ec2"
  tool_name     = var.tool_name
}

#--------------------------------------------------
# RDS
#--------------------------------------------------

resource "aws_db_parameter_group" "db_param_group" {
  # name   = "${var.project_name}-${var.environment}-db-param-group"
  family = "aurora-mysql5.7"

  tags = {
    Name         = "${var.project_name}-${var.environment}-db_param_group"
    Environment  = var.environment
    ProjectName  = var.project_name
    ResourceName = "db_param_group"
    Tool         = var.tool_name
  }
}

resource "aws_rds_cluster_parameter_group" "rds_cluster_param_group" {
  # name   = "${var.project_name}-${var.environment}-rds_cluster_param_group"
  family = "aurora-mysql5.7"

  tags = {
    Name         = "${var.project_name}-${var.environment}-rds_cluster_param_group"
    Environment  = var.environment
    ProjectName  = var.project_name
    ResourceName = "rds_cluster_param_group"
    Tool         = var.tool_name
  }

  parameter {
    name         = "character_set_client"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_connection"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_database"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_filesystem"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_results"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_server"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_connection"
    value        = "utf8mb4_general_ci"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_server"
    value        = "utf8mb4_general_ci"
    apply_method = "immediate"
  }

  parameter {
    name         = "time_zone"
    value        = "Asia/Tokyo"
    apply_method = "immediate"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "${var.project_name}-${var.environment}-db_subnet_group"
  subnet_ids = [
    module.network.private_subnet_1a_id,
    module.network.private_subnet_1c_id
  ]

  tags = {
    Name         = "${var.project_name}-${var.environment}-db_subnet_group"
    Environment  = var.environment
    ProjectName  = var.project_name
    ResourceName = "db_subnet_group"
    Tool         = var.tool_name
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier = "${var.project_name}-${var.environment}-aurora-cluster"

  engine          = "aurora-mysql"
  engine_version  = "5.7.mysql_aurora.2.10.2"
  master_username = "admin"
  master_password = "change_after_start"

  port                            = 3306
  vpc_security_group_ids          = [module.security_group_for_rds.security_group_id]
  db_subnet_group_name            = aws_db_subnet_group.db_subnet_group.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.rds_cluster_param_group.name

  # NOTE: 以下は設定しなくても起動するが、Destroyできなくなる
  skip_final_snapshot = true
  apply_immediately   = true

  lifecycle {
    # NOTE: リソース作成後、パスワードを変更する
    ignore_changes = ["master_password"]
  }

  tags = {
    Name         = "${var.project_name}-${var.environment}-aurora_cluster"
    Environment  = var.environment
    ProjectName  = var.project_name
    ResourceName = "aurora_cluster"
    Tool         = var.tool_name
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  count = "2"

  identifier              = "${var.project_name}-${var.environment}-aurora-instance-${count.index}"
  cluster_identifier      = aws_rds_cluster.aurora_cluster.id
  instance_class          = "db.t3.small"
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  db_parameter_group_name = aws_db_parameter_group.db_param_group.name

  tags = {
    Name         = "${var.project_name}-${var.environment}-aurora_instance_${count.index}"
    Environment  = var.environment
    ProjectName  = var.project_name
    ResourceName = "aurora_instance"
    Tool         = var.tool_name
  }
}
