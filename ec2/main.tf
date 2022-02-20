terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws = ">= 3.37.0"
  }
  backend "s3" {
    bucket = "tfstate-terraform-template"
    key    = "ec2/terraform.tfstate"
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

module "security_group_for_ec2" {
  source      = "../modules/security_group"
  vpc_id      = module.network.vpc_id
  port        = "80"
  cidr_blocks = ["0.0.0.0/0"]

  environment   = var.environment
  project_name  = var.project_name
  resource_name = "ec2"
  tool_name     = var.tool_name
}

#--------------------------------------------------
# EC2
#--------------------------------------------------

resource "aws_instance" "web_ec2_1a" {
  ami                    = "ami-08a8688fb7eacb171"
  subnet_id              = module.network.public_subnet_1a_id
  vpc_security_group_ids = [module.security_group_for_ec2.security_group_id]
  instance_type          = var.instance_type

  tags = {
    Name         = "${var.project_name}-${var.environment}-ec2_1a"
    Environment  = var.environment
    ProjectName  = var.project_name
    ResourceName = "ec2_1a"
    Tool         = var.tool_name
  }
}

resource "aws_instance" "web_ec2_1c" {
  ami                    = "ami-08a8688fb7eacb171"
  subnet_id              = module.network.public_subnet_1c_id
  vpc_security_group_ids = [module.security_group_for_ec2.security_group_id]
  instance_type          = var.instance_type

  tags = {
    Name         = "${var.project_name}-${var.environment}-ec2_1c"
    Environment  = var.environment
    ProjectName  = var.project_name
    ResourceName = "ec2_1c"
    Tool         = var.tool_name
  }
}

#--------------------------------------------------
# Elastic IP
#--------------------------------------------------

resource "aws_eip" "ec2_1a_eip" {
  vpc      = true
  instance = aws_instance.web_ec2_1a.id

  tags = {
    Name         = "${var.project_name}-${var.environment}-ec2_1a_eip"
    Environment  = var.environment
    ProjectName  = var.project_name
    ResourceName = "ec2_1a_eip"
    Tool         = var.tool_name
  }
}

resource "aws_eip" "ec2_1c_eip" {
  vpc      = true
  instance = aws_instance.web_ec2_1c.id

  tags = {
    Name         = "${var.project_name}-${var.environment}-ec2_1c_eip"
    Environment  = var.environment
    ProjectName  = var.project_name
    ResourceName = "ec2_1c_eip"
    Tool         = var.tool_name
  }
}
