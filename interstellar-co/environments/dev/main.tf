# ── environments/dev/main.tf ────────────────────────────────
# Dev environment root module.
#
# Dependency order:
#   1. module.s3          — creates the private website bucket
#   2. module.cloudfront  — creates the CDN; outputs the distribution ARN
#   3. module.s3 (policy) — bucket policy applied via cloudfront_distribution_arn
#      NOTE: the OAC bucket policy is a separate aws_s3_bucket_policy resource
#      inside the s3 module, so we must pass the CloudFront ARN back in.
#      Terraform handles the ordering automatically via the reference.
#   4. module.iam         — deploy role referencing both bucket and CF ARNs
#
# Because the S3 bucket policy depends on the CloudFront distribution ARN,
# and CloudFront depends on the S3 bucket domain, there's a natural two-pass
# dependency. Terraform resolves this without any workarounds.

# ── Terraform backend (configured via backend.hcl) ── #
terraform {
  backend "s3" {}
}

# ── S3 Website Bucket ──────────────────────────────────────── #
# First pass: create the bucket WITHOUT the bucket policy.
# The policy requires the CloudFront ARN, which doesn't exist yet.
module "s3" {
  source = "../../modules/s3"

  bucket_name = var.website_bucket_name
  environment = var.environment
  project     = var.project

  # Wire in the CF ARN after CloudFront is created.
  # On first apply this is empty → policy resource count = 0.
  # On subsequent applies (or with -target ordering) it is populated.
  cloudfront_distribution_arn = module.cloudfront.distribution_arn

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ── CloudFront Distribution ────────────────────────────────── #
module "cloudfront" {
  source = "../../modules/cloudfront"

  environment                    = var.environment
  project                        = var.project
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  s3_bucket_id                   = module.s3.bucket_id
  acm_certificate_arn            = var.acm_certificate_arn
  aliases                        = var.domain_aliases
  price_class                    = var.cloudfront_price_class

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ── IAM Deploy Role ────────────────────────────────────────── #
module "iam" {
  source = "../../modules/iam"

  environment                 = var.environment
  project                     = var.project
  s3_bucket_arn               = module.s3.bucket_arn
  cloudfront_distribution_arn = module.cloudfront.distribution_arn

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ── DynamoDB State Lock Table ──────────────────────────────── #
# Pre-provision the lock table in the same environment so it's tracked
# in state. Note: this table is referenced by backend.hcl — if you're
# bootstrapping for the first time, you may need to create it manually
# or with a one-time local backend, then migrate state.
resource "aws_dynamodb_table" "tf_lock" {
  name         = "interstellar-co-tflock-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Protect the lock table from accidental deletion in all environments.
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Purpose     = "terraform-state-locking"
  }
}

# ── Outputs ────────────────────────────────────────────────── #
output "website_bucket_name" {
  description = "Name of the website S3 bucket."
  value       = module.s3.bucket_id
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain — use this URL to access the dev site."
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — needed for cache invalidation during deploy."
  value       = module.cloudfront.distribution_id
}

output "deploy_role_arn" {
  description = "IAM role ARN your CI/CD pipeline should assume to deploy website files."
  value       = module.iam.deploy_role_arn
}
