# ── interstellar-co/main.tf ──────────────────────────────────
# Dev environment root — provisions the full static-site stack:
#
#   S3 (private bucket) → CloudFront (OAC distribution) → IAM (OIDC roles)
#
# Dependency order Terraform resolves automatically:
#   1. module.s3          creates the bucket (no bucket policy yet)
#   2. module.cloudfront  creates the distribution; outputs its ARN
#   3. module.s3          applies the bucket policy using the CF ARN
#   4. module.iam         creates deploy + terraform roles referencing both ARNs
#
# On the very first apply the cloudfront_distribution_arn passed to module.s3
# is a known value (Terraform resolves the reference in-plan), so no two-pass
# apply is required.

# ── S3 Website Bucket ──────────────────────────────────────── #
module "s3" {
  source = "./modules/s3"

  bucket_name = var.website_bucket_name
  environment = var.environment
  project     = var.project

  # CloudFront ARN — wired in from module.cloudfront.
  # Terraform resolves this dependency automatically within a single plan+apply.
  cloudfront_distribution_arn = module.cloudfront.distribution_arn

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ── CloudFront Distribution ────────────────────────────────── #
module "cloudfront" {
  source = "./modules/cloudfront"

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

# ── IAM — OIDC Roles for GitHub Actions ───────────────────── #
module "iam" {
  source = "./modules/iam"

  environment                 = var.environment
  project                     = var.project
  s3_bucket_arn               = module.s3.bucket_arn
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  tf_state_bucket_arn         = "arn:aws:s3:::${var.tf_state_bucket_name}"

  create_oidc_provider = var.create_oidc_provider
  github_oidc_subjects = var.github_oidc_subjects

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ── DynamoDB State Lock Table ──────────────────────────────── #
# Tracks in-progress Terraform operations to prevent concurrent runs.
# NOTE: This table is referenced by backend.hcl BEFORE init runs.
#   Bootstrap sequence for a brand new account:
#     1. Create the S3 state bucket and DynamoDB table manually (or via aws cli).
#     2. terraform init -backend-config=backend.hcl
#     3. terraform apply
#   After the first apply, the table is owned by this state and future
#   applies manage it automatically.
resource "aws_dynamodb_table" "tf_lock" {
  name         = "interstellar-co-tflock-dev"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

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
  description = "S3 bucket name — needed by the deploy workflow to sync files."
  value       = module.s3.bucket_id
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain (e.g. d1234abcd.cloudfront.net)."
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — used for cache invalidation in the deploy workflow."
  value       = module.cloudfront.distribution_id
}

output "deploy_role_arn" {
  description = "IAM role ARN for the GitHub Actions deploy step (S3 sync + CloudFront invalidation)."
  value       = module.iam.deploy_role_arn
}

output "terraform_role_arn" {
  description = "IAM role ARN for the GitHub Actions Terraform plan/apply steps."
  value       = module.iam.terraform_role_arn
}
