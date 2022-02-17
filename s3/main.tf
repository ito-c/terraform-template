terraform {
  backend "s3" {
    bucket = "tfstate-terraform-study"
    key    = "s3/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

resource "aws_s3_bucket" "private" {
  bucket = "private-bucket-terraform"

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
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "public" {
  bucket = "public-bucket-terraform"
  acl    = "public-read" # デフォルトはprivate

  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "alb_log" {
  bucket        = "alb-log-terraform"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "alb-log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb-log.json
}

# ALBログを書き込むためのIAMポリシー
data "aws_iam_policy_document" "alb-log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
      # identifiers = ["${data.aws_elb_service_account.alb-log.id}"]
    }
  }
}
