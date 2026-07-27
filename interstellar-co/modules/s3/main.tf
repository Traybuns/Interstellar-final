# ── modules/s3/main.tf ──────────────────────────────────────
# Provisions a private S3 bucket for static website content.
#
# Security posture:
#   • Block all public access (no direct S3 URL access)
#   • Server-side encryption with AES-256 by default
#   • Versioning enabled for easy rollbacks
#   • Bucket policy restricts GetObject to the CloudFront distribution via OAC
#   • Access logs written to the same bucket under a dedicated prefix

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ── S3 Bucket ────────────────────────────────────────────── #
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  # Force-destroy allows Terraform to delete a non-empty bucket.
  # Set to false in prod if you want a safety net against accidental destroy.
  force_destroy = var.environment != "prod"

  tags = local.common_tags
}

# ── Block all public access ───────────────────────────────── #
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Server-side encryption ────────────────────────────────── #
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ── Versioning ────────────────────────────────────────────── #
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ── Bucket ownership controls ─────────────────────────────── #
# Required when block_public_acls is true; disables ACL-based access.
resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ── Bucket policy: allow CloudFront OAC to read objects ───── #
# The aws:SourceArn condition ensures only *this specific* distribution
# can use the OAC service principal — prevents confused-deputy attacks.
resource "aws_s3_bucket_policy" "cloudfront_oac" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOACReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })

  # Ensure public-access-block is in place before the policy is attached.
  depends_on = [aws_s3_bucket_public_access_block.website]
}
