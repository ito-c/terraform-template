output "terraform_template_vpc_id" {
  value = aws_vpc.terraform_template.id
}

output "terraform_template_subnet_public_1a_id" {
  value = aws_subnet.public_1a.id
}

output "terraform_template_subnet_public_1c_id" {
  value = aws_subnet.public_1c.id
}
