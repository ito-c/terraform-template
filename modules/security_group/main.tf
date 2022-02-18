resource "aws_security_group" "default" {
  name   = "${var.project_name}-${var.environment}-security-group-for-${var.resource_name}"
  vpc_id = var.vpc_id

  tags = {
    Name         = "${var.project_name}-${var.environment}-for-${var.resource_name}"
    ProjectName  = var.project_name
    Environment  = var.environment
    ResourceName = var.resource_name
    Tool         = var.tool_name
  }
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks
  security_group_id = aws_security_group.default.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}
