terraform {
  backend "s3" {
    bucket = "tfstate-terraform-study"
    key    = "network/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

resource "aws_vpc" "terraform_study" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform_study"
  }
}

# *********************
# パブリックサブネット
# *********************

resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.terraform_study.id
  cidr_block              = "172.16.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "terraform_study"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.terraform_study.id
  cidr_block              = "172.16.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name = "terraform_study"
  }
}

resource "aws_internet_gateway" "terraform_study" {
  vpc_id = aws_vpc.terraform_study.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.terraform_study.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.terraform_study.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# *********************
# プライベートサブネット
# *********************

resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.terraform_study.id
  cidr_block              = "172.16.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "terraform_study"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.terraform_study.id
  cidr_block              = "172.16.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name = "terraform_study"
  }
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.terraform_study.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.terraform_study.id
}

resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.terraform_study_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.terraform_study_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_eip" "nat_gateway_0" {
  vpc = true

  depends_on = [
    aws_internet_gateway.terraform_study
  ]
}

resource "aws_eip" "nat_gateway_1" {
  vpc = true

  depends_on = [
    aws_internet_gateway.terraform_study
  ]
}

resource "aws_nat_gateway" "terraform_study_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id

  depends_on = [
    aws_internet_gateway.terraform_study
  ]
}

resource "aws_nat_gateway" "terraform_study_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id

  depends_on = [
    aws_internet_gateway.terraform_study
  ]
}


