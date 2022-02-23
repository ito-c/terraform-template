data "aws_vpc" "main" {
  tags = {
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "vpc"
  }
}

data "aws_subnet" "private_1a_db" {
  tags = {
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "private-subnet-1a-db"
  }
}

data "aws_subnet" "private_1c_db" {
  tags = {
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "private-subnet-1c-db"
  }
}

output "vpc_id" {
  description = "The ID of the vpc."
  value       = data.aws_vpc.main.id
}

output "private_subnet_1a_db_id" {
  description = "The ID of the private subnet 1a for db."
  value       = data.aws_subnet.private_1a_db.id
}

output "private_subnet_1c_db_id" {
  description = "The ID of the private subnet 1c for db."
  value       = data.aws_subnet.private_1c_db.id
}
