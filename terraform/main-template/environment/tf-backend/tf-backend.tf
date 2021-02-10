terraform {
  required_version = ">= 0.13.2"
}

provider "aws" {
  version = ">= 3.5.0"
  region  = "ap-southeast-2"
}

# parameter settings
locals {
  pj   = "tf-cicd"
  tags = {
    pj     = "tf-cicd"
    owner = "nobody"
  }
}

# delivery
resource "aws_s3_bucket" "tfstate_delivery" {
  bucket        = "${lower(local.pj)}-tfstate-delivery"
  acl           = "private"

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

  tags = merge(
  {
    "Name" = "${lower(local.pj)}-tfstate-delivery"
  },
  local.tags
  )
}

resource "aws_s3_bucket_public_access_block" "tfstate_delivery" {
  bucket = aws_s3_bucket.tfstate_delivery.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tfstate_lock_delivery" {
  name           = "${local.pj}-tfstate-lock-delivery"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# dev
resource "aws_s3_bucket" "tfstate_dev" {
  bucket        = "${lower(local.pj)}-tfstate-dev"
  acl           = "private"

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

  tags = merge(
  {
    "Name" = "${lower(local.pj)}-tfstate-dev"
  },
  local.tags
  )
}

resource "aws_s3_bucket_public_access_block" "tfstate_dev" {
  bucket = aws_s3_bucket.tfstate_dev.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tfstate_lock_dev" {
  name           = "${local.pj}-tfstate-lock-dev"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# prod
resource "aws_s3_bucket" "tfstate_prod" {
  bucket        = "${lower(local.pj)}-tfstate-prod"
  acl           = "private"

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

  tags = merge(
  {
    "Name" = "${lower(local.pj)}-tfstate-prod"
  },
  local.tags
  )
}

resource "aws_s3_bucket_public_access_block" "tfstate_prod" {
  bucket = aws_s3_bucket.tfstate_prod.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tfstate_lock_prod" {
  name           = "${local.pj}-tfstate-lock-prod"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

