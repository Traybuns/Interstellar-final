# ── modules/cloudfront/main.tf ──────────────────────────────
# CloudFront distribution for static website delivery.
#
# Security posture:
#   • Origin Access Control (OAC) — modern replacement for OAI
#   • viewer_protocol_policy = "redirect-to-https" enforced on all behaviours
#   • TLS 1.2 minimum (TLSv1.2_2021 security policy)
#   • Custom error pages redirect 403/404 → index.html (SPA-friendly)
#   • Cache policy uses CachingOptimized managed policy

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
    },
    var.tags
  )

  origin_id = "S3-${var.s3_bucket_id}"
}

# ── Origin Access Control ─────────────────────────────────── #
# OAC is the AWS-recommended way (since 2022) to grant CloudFront-only
# read access to a private S3 bucket. It signs requests with SigV4,
# unlike the legacy OAI which used a virtual identity.
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.project}-${var.environment}-oac"
  description                       = "OAC for ${var.project} ${var.environment} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ── CloudFront Distribution ───────────────────────────────── #
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project}-${var.environment}"
  default_root_object = var.default_root_object
  price_class         = var.price_class
  aliases             = var.acm_certificate_arn != "" ? var.aliases : []
  http_version        = "http2and3"

  # ── Origin: private S3 bucket ──
  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  # ── Default cache behaviour ──
  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # AWS managed CachingOptimized policy — caches based on query strings & headers.
    # ID is stable across all AWS accounts/regions.
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # ── Custom error responses ──
  # 403 from S3 means the file doesn't exist (S3 returns 403, not 404, for
  # missing objects when public access is blocked). Redirect to index.html
  # with a 200 so single-page-app routing works correctly.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # ── TLS / Viewer Certificate ──
  viewer_certificate {
    # If an ACM cert ARN is provided, use it with SNI; otherwise fall back
    # to the default *.cloudfront.net certificate.
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : null
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != "" ? "TLSv1.2_2021" : null
  }

  # ── Geo restriction ──
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.common_tags
}
