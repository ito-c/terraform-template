terraform {
  backend "s3" {
    bucket = "tfstate-terraform-study"
    key    = "alb/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "tfstate-terraform-study"
    key    = "network/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"

  config = {
    bucket = "tfstate-terraform-study"
    key    = "s3/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

resource "aws_lb" "terraform_study" {
  name                       = "terraform-study"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    data.terraform_remote_state.network.outputs.terraform_study_subnet_public_0_id,
    data.terraform_remote_state.network.outputs.terraform_study_subnet_public_1_id
  ]

  access_logs {
    bucket  = data.terraform_remote_state.s3.outputs.alb_log_id
    enabled = true
  }

  security_groups = [
    module.http_sg.security_group_id
  ]
}

module "http_sg" {
  source        = "../modules/security_group"
  vpc_id        = data.terraform_remote_state.network.outputs.terraform_study_vpc_id
  port          = "80"
  cidr_blocks   = ["0.0.0.0/0"]
  resource_name = "alb"
  environment   = "dev"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.terraform_study.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これはHTTPです"
      status_code  = "200"
    }
  }
}
