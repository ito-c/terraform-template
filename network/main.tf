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

#--------------------------------------------------
# VPC
#--------------------------------------------------

resource "aws_vpc" "terraform_template" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name         = "terraform-template-dev-vpc"
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "vpc"
    Tool         = "terraform"
  }
}

#--------------------------------------------------
# Public subnet
#--------------------------------------------------

resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.terraform_template.id
  cidr_block              = "172.16.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name         = "terraform-template-dev-public-subnet-0"
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "public-subnet-0"
    Tool         = "terraform"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.terraform_template.id
  cidr_block              = "172.16.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name         = "terraform-template-dev-public-subnet-1"
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "public-subnet-1"
    Tool         = "terraform"
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
  cidr_block              = "172.16.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name         = "terraform-template-dev-private-subnet-1a"
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "private-subnet-1a"
    Tool         = "terraform"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id                  = aws_vpc.terraform_template.id
  cidr_block              = "172.16.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name         = "terraform-template-dev-private-subnet-1c"
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "private-subnet-1c"
    Tool         = "terraform"
  }
}

resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.terraform_template.id
}

resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.terraform_template.id
}

resource "aws_route" "private_1a" {
  route_table_id         = aws_route_table.private_1a.id
  nat_gateway_id         = aws_nat_gateway.terraform_template_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1c" {
  route_table_id         = aws_route_table.private_1c.id
  nat_gateway_id         = aws_nat_gateway.terraform_template_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}

#--------------------------------------------------
# NAT Gateway
#--------------------------------------------------

resource "aws_eip" "nat_gateway_0" {
  vpc = true

  depends_on = [
    aws_internet_gateway.terraform_template
  ]
}

resource "aws_eip" "nat_gateway_1" {
  vpc = true

  depends_on = [
    aws_internet_gateway.terraform_template
  ]
}

resource "aws_nat_gateway" "terraform_template_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_1a.id

  depends_on = [
    aws_internet_gateway.terraform_template
  ]
}

resource "aws_nat_gateway" "terraform_template_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1c.id

  depends_on = [
    aws_internet_gateway.terraform_template
  ]
}


