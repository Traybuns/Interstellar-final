# ── environments/staging/main.tf ────────────────────────────
# Staging environment root module. Identical structure to dev;
# variables in terraform.tfvars differ.

terraform {
  backend "s3" {}
}

module "s3" {
  source = "../../modules/s3"

  bucket_name                 = var.website_bucket_name
  environment                 = var.environment
  project                     = var.project
  cloudfront_distribution_arn = module.cloudfront.distribution_arn

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

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

module "iam" {
  source = "../../modules/iam"

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

resource "aws_dynamodb_table" "tf_lock" {
  name         = "interstellar-co-tflock-${var.environment}"
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

output "website_bucket_name" {
  value = module.s3.bucket_id
}

output "cloudfront_domain" {
  value = module.cloudfront.distribution_domain_name
}

output "cloudfront_distribution_id" {
  value = module.cloudfront.distribution_id
}

output "deploy_role_arn" {
  value = module.iam.deploy_role_arn
}

output "terraform_role_arn" {
  value = module.iam.terraform_role_arn
}
