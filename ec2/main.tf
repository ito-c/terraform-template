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
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

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
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

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

#--------------------------------------------------
# Profile
#--------------------------------------------------

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "for_ec2" {
  name               = "${var.project_name}-${var.environment}-iam_role_for_ec2"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name         = "${var.project_name}-${var.environment}-iam_role_for_ec2"
    Environment  = var.environment
    ProjectName  = var.project_name
    ResourceName = "iam_role_for_ec2"
    Tool         = var.tool_name
  }
}

data "aws_iam_policy" "ssm_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "s3_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.for_ec2.name
  policy_arn = data.aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.for_ec2.name
  policy_arn = data.aws_iam_policy.s3_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "profile_for_ec2"
  role = aws_iam_role.for_ec2.name
}
