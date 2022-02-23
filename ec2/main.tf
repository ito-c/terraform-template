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

locals {
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

module "security_group_for_ec2" {
  source      = "../modules/security_group"
  vpc_id      = module.network.vpc_id
  port        = "80"
  cidr_blocks = ["0.0.0.0/0"]

  environment   = local.environment
  project_name  = local.projectName
  resource_name = "ec2"
  tool_name     = local.toolName
}

#--------------------------------------------------
# EC2
#--------------------------------------------------

resource "aws_instance" "web_ec2_1a" {
  ami                    = "ami-08a8688fb7eacb171"
  subnet_id              = module.network.public_subnet_1a_id
  vpc_security_group_ids = [module.security_group_for_ec2.security_group_id]
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name         = "${local.namePrefix}-ec2-1a"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "ec2-1a"
    Tool         = local.toolName
  }
}

resource "aws_instance" "web_ec2_1c" {
  ami                    = "ami-08a8688fb7eacb171"
  subnet_id              = module.network.public_subnet_1c_id
  vpc_security_group_ids = [module.security_group_for_ec2.security_group_id]
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name         = "${local.namePrefix}-ec2-1c"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "ec2-1c"
    Tool         = local.toolName
  }
}

#--------------------------------------------------
# Elastic IP
#--------------------------------------------------

resource "aws_eip" "ec2_1a_eip" {
  vpc      = true
  instance = aws_instance.web_ec2_1a.id

  tags = {
    Name         = "${local.namePrefix}-ec2-1a-eip"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "ec2-1a-eip"
    Tool         = local.toolName
  }
}

resource "aws_eip" "ec2_1c_eip" {
  vpc      = true
  instance = aws_instance.web_ec2_1c.id

  tags = {
    Name         = "${local.namePrefix}-ec2-1c-eip"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "ec2-1c-eip"
    Tool         = local.toolName
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

#--------------------------------------------------
# IAM
#--------------------------------------------------

resource "aws_iam_role" "for_ec2" {
  name               = "${local.namePrefix}-iam-role-for-ec2"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name         = "${local.namePrefix}-iam-role-for-ec2"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "iam-role-for-ec2"
    Tool         = local.toolName
  }
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.for_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.for_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "profile_for_ec2"
  role = aws_iam_role.for_ec2.name
}
