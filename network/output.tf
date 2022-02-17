output "terraform_study_vpc_id" {
  value = aws_vpc.terraform_study.id
}

output "terraform_study_subnet_public_0_id" {
  value = aws_subnet.public_0.id
}

output "terraform_study_subnet_public_1_id" {
  value = aws_subnet.public_1.id
}
