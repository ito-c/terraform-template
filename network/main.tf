terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws = ">= 3.37.0"
  }
  backend "s3" {
    bucket = "tfstate-terraform-template"
    key    = "network/terraform.tfstate"
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
# VPC
#--------------------------------------------------

resource "aws_vpc" "terraform_template" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name         = "${local.namePrefix}-vpc"
    ProjectName  = local.projectName
    Environment  = local.environment
    ResourceName = "vpc"
    Tool         = local.toolName
  }
}

#--------------------------------------------------
# Public subnet
#--------------------------------------------------

resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.terraform_template.id
  cidr_block              = cidrsubnet(aws_vpc.terraform_template.cidr_block, 8, 0)
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name         = "${local.namePrefix}-public-subnet-1a"
    ProjectName  = local.projectName
    Environment  = local.environment
    ResourceName = "public-subnet-1a"
    Tool         = local.toolName

  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.terraform_template.id
  cidr_block              = cidrsubnet(aws_vpc.terraform_template.cidr_block, 8, 1)
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name         = "${local.namePrefix}-public-subnet-1c"
    ProjectName  = local.projectName
    Environment  = local.environment
    ResourceName = "public-subnet-1c"
    Tool         = local.toolName
  }
}

resource "aws_internet_gateway" "terraform_template" {
  vpc_id = aws_vpc.terraform_template.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.terraform_template.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.terraform_template.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

#--------------------------------------------------
# Private subnet
#--------------------------------------------------

resource "aws_subnet" "private_1a" {
  vpc_id                  = aws_vpc.terraform_template.id
  cidr_block              = cidrsubnet(aws_vpc.terraform_template.cidr_block, 8, 2)
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name         = "${local.namePrefix}-private-subnet-1a"
    ProjectName  = local.projectName
    Environment  = local.environment
    ResourceName = "private-subnet-1a"
    Tool         = local.toolName
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id                  = aws_vpc.terraform_template.id
  cidr_block              = cidrsubnet(aws_vpc.terraform_template.cidr_block, 8, 3)
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name         = "${local.namePrefix}-private-subnet-1c"
    ProjectName  = local.projectName
    Environment  = local.environment
    ResourceName = "private-subnet-1c"
    Tool         = local.toolName

  }
}

# resource "aws_route_table" "private_1a" {
#   vpc_id = aws_vpc.terraform_template.id
# }

# resource "aws_route_table" "private_1c" {
#   vpc_id = aws_vpc.terraform_template.id
# }

# resource "aws_route" "private_1a" {
#   route_table_id         = aws_route_table.private_1a.id
#   nat_gateway_id         = aws_nat_gateway.terraform_template_0.id
#   destination_cidr_block = "0.0.0.0/0"
# }

# resource "aws_route" "private_1c" {
#   route_table_id         = aws_route_table.private_1c.id
#   nat_gateway_id         = aws_nat_gateway.terraform_template_1.id
#   destination_cidr_block = "0.0.0.0/0"
# }

# resource "aws_route_table_association" "private_1a" {
#   subnet_id      = aws_subnet.private_1a.id
#   route_table_id = aws_route_table.private_1a.id
# }

# resource "aws_route_table_association" "private_1c" {
#   subnet_id      = aws_subnet.private_1c.id
#   route_table_id = aws_route_table.private_1c.id
# }

#--------------------------------------------------
# NAT Gateway
#--------------------------------------------------

# resource "aws_eip" "nat_gateway_0" {
#   vpc = true

#   depends_on = [
#     aws_internet_gateway.terraform_template
#   ]
# }

# resource "aws_eip" "nat_gateway_1" {
#   vpc = true

#   depends_on = [
#     aws_internet_gateway.terraform_template
#   ]
# }

# resource "aws_nat_gateway" "terraform_template_0" {
#   allocation_id = aws_eip.nat_gateway_0.id
#   subnet_id     = aws_subnet.public_1a.id

#   depends_on = [
#     aws_internet_gateway.terraform_template
#   ]
# }

# resource "aws_nat_gateway" "terraform_template_1" {
#   allocation_id = aws_eip.nat_gateway_1.id
#   subnet_id     = aws_subnet.public_1c.id

#   depends_on = [
#     aws_internet_gateway.terraform_template
#   ]
# }
