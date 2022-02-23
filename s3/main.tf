terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws = ">= 3.37.0"
  }
  backend "s3" {
    bucket = "tfstate-terraform-template"
    key    = "s3/terraform.tfstate"
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
# private bucket
#--------------------------------------------------

resource "aws_s3_bucket" "private" {
  bucket = "${local.namePrefix}-private-bucket"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name         = "${local.namePrefix}-private-bucket"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "private-bucket"
    Tool         = local.toolName
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#--------------------------------------------------
# public bucket
#--------------------------------------------------

resource "aws_s3_bucket" "public" {
  bucket = "${local.namePrefix}-public-bucket"
  acl    = "public-read" # デフォルトはprivate

  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }

  tags = {
    Name         = "${local.namePrefix}-public-bucket"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "public-bucket"
    Tool         = local.toolName
  }
}

#--------------------------------------------------
# alb log bucket
#--------------------------------------------------

resource "aws_s3_bucket" "alb_log" {
  bucket        = "${local.namePrefix}-alb-log-bucket"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "7"
    }
  }

  tags = {
    Name         = "${local.namePrefix}-alb-log-bucket"
    Environment  = local.environment
    ProjectName  = local.projectName
    ResourceName = "alb-log-bucket"
    Tool         = local.toolName
  }
}


#--------------------------------------------------
# IAM
#--------------------------------------------------

data "aws_elb_service_account" "current" {}

output "alb_service_account_id" {
  value = data.aws_elb_service_account.current.id
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

# ALBログを書き込むためのIAMポリシー
data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.alb_log.id}"]
      # TODO: 修正
      # identifiers = ["582318560864"]
    }
  }
}
