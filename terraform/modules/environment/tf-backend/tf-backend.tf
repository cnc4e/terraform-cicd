resource "aws_s3_bucket" "tfstate" {
  count         = length(var.env_names)
  bucket        = "${lower(var.pj)}-tfstate-${lower(var.env_names[count.index])}"
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
    "Name" = "${lower(var.pj)}-tfstate-${lower(var.env_names[count.index])}"
  },
  var.tags
  )
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  count   = length(var.env_names)
  bucket  = aws_s3_bucket.tfstate[count.index].bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tfstate_lock" {
  count          = length(var.env_names)
  name           = "${var.pj}-tfstate-lock-${lower(var.env_names[count.index])}"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}