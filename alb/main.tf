terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws = ">= 3.37.0"
  }
  backend "s3" {
    bucket = "tfstate-terraform-template"
    key    = "alb/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

locals {
  projectName = "terraform-template"
  environment = "dev"
  namePrefix  = "${local.projectName}-${local.environment}"
  toolName    = "terraform"
}

#--------------------------------------------------
# Data only Modules
#--------------------------------------------------

module "network" {
  source = "./network"
}

#--------------------------------------------------
# Securiry Group
#--------------------------------------------------

module "security_group_for_alb" {
  source      = "../modules/security_group"
  vpc_id      = module.network.vpc_id
  port        = "80"
  cidr_blocks = ["0.0.0.0/0"]

  environment   = local.environment
  project_name  = local.projectName
  resource_name = "alb"
  tool_name     = local.toolName
}

#--------------------------------------------------
# Target group
#--------------------------------------------------

data "aws_instance" "web_ec2_1a" {
  instance_tags = {
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "ec2-1a"
  }
}

data "aws_instance" "web_ec2_1c" {
  instance_tags = {
    ProjectName  = "terraform-template"
    Environment  = "dev"
    ResourceName = "ec2-1c"
  }
}

resource "aws_lb_target_group" "tg_ec2" {
  name     = "${local.namePrefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id

  health_check {
    protocol            = "HTTP"
    path                = "/"
    port                = "80"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 100
    matcher             = 200
  }

  tags = {
    Name         = "${local.namePrefix}-tg-ec2"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "tg-ec2"
    Tool         = local.toolName
  }
}

resource "aws_lb_target_group_attachment" "attach_web_ec2_1a" {
  target_group_arn = aws_lb_target_group.tg_ec2.arn
  target_id        = data.aws_instance.web_ec2_1a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach_web_ec2_1c" {
  target_group_arn = aws_lb_target_group.tg_ec2.arn
  target_id        = data.aws_instance.web_ec2_1c.id
  port             = 80
}

#--------------------------------------------------
# ALB
#--------------------------------------------------

data "aws_s3_bucket" "alb_log" {
  bucket = "terraform-template-dev-alb-log-bucket"
}

resource "aws_lb" "alb" {
  name                       = "${local.namePrefix}-alb"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    module.network.public_subnet_1a_id,
    module.network.public_subnet_1c_id,
  ]

  access_logs {
    bucket  = data.aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.security_group_for_alb.security_group_id
  ]

  tags = {
    Name         = "${local.namePrefix}-alb"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "alb"
    Tool         = local.toolName
  }
}

#--------------------------------------------------
# Listener
#--------------------------------------------------

resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg_ec2.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "redirect_google" {
  listener_arn = aws_lb_listener.alb_http_listener.arn

  action {
    type = "redirect"

    redirect {
      host        = "google.co.jp"
      port        = "443"
      path        = "/"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/google"]
    }
  }
}

resource "aws_lb_listener_rule" "fixed_response" {
  listener_arn = aws_lb_listener.alb_http_listener.arn

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これはHTTPです"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/test"]
    }
  }
}

resource "aws_lb_listener_rule" "health_check" {
  listener_arn = aws_lb_listener.alb_http_listener.arn

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "HEALTHY"
      status_code  = "200"
    }
  }

  condition {
    query_string {
      key   = "health"
      value = "check"
    }

    query_string {
      value = "bar"
    }
  }
}
