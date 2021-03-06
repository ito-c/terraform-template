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
locals {
  engine        = "aurora-mysql"
  engineVersion = "5.7.mysql_aurora.2.10.2"

  projectName = "terraform-template"
  environment = "dev"
  namePrefix  = "${local.projectName}-${local.environment}"
  toolName    = "terraform"
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

# インバウンドでSGを指定するためEC2にアタッチしているSGを登録
data "aws_security_group" "ec2" {
  tags = {
    ProjectName  = "terraform-template"
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

  environment   = local.environment
  project_name  = local.projectName
  resource_name = "rds"
  tool_name     = local.toolName
}

#--------------------------------------------------
# RDS
#--------------------------------------------------

resource "aws_db_parameter_group" "db_param_group" {
  name   = "${local.namePrefix}-db-param-group"
  family = "aurora-mysql5.7"

  tags = {
    Name         = "${local.namePrefix}-db-param-group"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "db-param-group"
    Tool         = local.toolName
  }
}

resource "aws_rds_cluster_parameter_group" "rds_cluster_param_group" {
  name   = "${local.namePrefix}-rds-cluster-param-group"
  family = "aurora-mysql5.7"

  tags = {
    Name         = "${local.namePrefix}-rds-cluster-param-group"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "rds-cluster-param-group"
    Tool         = local.toolName
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
  name = "${local.namePrefix}-db-subnet-group"
  subnet_ids = [
    module.network.private_subnet_1a_db_id,
    module.network.private_subnet_1c_db_id
  ]

  tags = {
    Name         = "${local.namePrefix}-db-subnet-group"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "db-subnet-group"
    Tool         = local.toolName
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier = "${local.namePrefix}-aurora-cluster"

  engine          = local.engine
  engine_version  = local.engineVersion
  master_username = "admin"
  master_password = "change_after_start"

  backup_retention_period      = 1
  preferred_backup_window      = "18:00-19:00"
  preferred_maintenance_window = "wed:19:15-wed:19:45"

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
    Name         = "${local.namePrefix}-aurora-cluster"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "aurora-cluster"
    Tool         = local.toolName
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  count = "2"

  identifier         = "${local.namePrefix}-aurora-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_cluster.cluster_identifier
  engine             = local.engine
  engine_version     = local.engineVersion
  instance_class     = "db.t3.small"

  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  db_parameter_group_name = aws_db_parameter_group.db_param_group.name

  tags = {
    Name         = "${local.namePrefix}-aurora-instance-${count.index}"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "aurora-instance"
    Tool         = local.toolName
  }
}
