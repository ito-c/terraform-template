variable "vpc_id" {}
variable "port" {}
variable "cidr_blocks" {
  description = "cidr blocks"
  type        = list(string)
  default     = ["Your Value Here"]
}
variable "is_specified_sg" {
  description = "whether or not given sg id"
  default     = false
}
variable "source_security_group_id" {
  description = "specify security group id"
  default     = "Your Value Here"
}
variable "resource_name" {
  description = "project name"
  type        = string
  default     = "Your Value Here"
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
