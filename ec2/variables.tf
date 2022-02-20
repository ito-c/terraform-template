variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default = "t2.micro"
}
variable "project_name" {
  description = "project name"
  type        = string
  default     = "terraform_template"
}
variable "tool_name" {
  description = "tool name"
  type        = string
  default     = "terraform"
}
variable "environment" {
  description = "environment"
  type        = string
  default     = "dev"
}