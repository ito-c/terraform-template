variable "vpc_id" {}
variable "port" {}
variable "cidr_blocks" {
  type = list(string)
}
variable "project_name" {}
variable "resource_name" {}
variable "environment" {}
variable "tool_name" {}
