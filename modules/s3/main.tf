locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "s3"
  })
}

resource "aws_s3_bucket" "this" {
  bucket = "${local.name_prefix}-${var.bucket_purpose}"

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-${var.bucket_purpose}" })
}

# Blocks ALL public access at the bucket level regardless of any object ACL
# or bucket policy mistake — the single most common cause of S3 data leaks
# is a missing version of exactly this resource.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "storage-tiering"
    status = "Enabled"

    filter {}

    transition {
      days          = var.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_to_glacier_days
      storage_class = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}
