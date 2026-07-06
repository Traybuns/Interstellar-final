# ── environments/prod/variables.tf ──────────────────────────

variable "aws_region" {
  description = "Primary AWS region for prod resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name — always 'prod' for this directory."
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project slug used in resource names and tags."
  type        = string
  default     = "interstellar-co"
}

variable "website_bucket_name" {
  description = "Globally unique name for the prod website S3 bucket."
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class. Prod uses PriceClass_All for global reach."
  type        = string
  default     = "PriceClass_All"
}

variable "acm_certificate_arn" {
  description = "ACM cert ARN (us-east-1) for the production custom domain. Required for prod."
  type        = string
  # No default — prod must have a real cert ARN
}

variable "domain_aliases" {
  description = "Custom domain aliases for the CloudFront distribution (e.g. [\"interstellar.co\", \"www.interstellar.co\"])."
  type        = list(string)
  default     = []
}
