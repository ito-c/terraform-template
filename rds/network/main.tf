data "aws_vpc" "main" {
  tags = {
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "vpc"
  }
}

data "aws_subnet" "private_1a" {
  tags = {
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "private-subnet-1a"
  }
}

data "aws_subnet" "private_1c" {
  tags = {
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "private-subnet-1c"
  }
}

output "vpc_id" {
  description = "The ID of the vpc."
  value       = data.aws_vpc.main.id
}

output "private_subnet_1a_id" {
  description = "The ID of the private subnet 1a."
  value       = data.aws_subnet.private_1a.id
}

output "private_subnet_1c_id" {
  description = "The ID of the private subnet 1c."
  value       = data.aws_subnet.private_1c.id
}
