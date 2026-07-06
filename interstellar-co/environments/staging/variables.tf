# ── environments/staging/variables.tf ───────────────────────

variable "aws_region" {
  description = "Primary AWS region for staging resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name — always 'staging' for this directory."
  type        = string
  default     = "staging"
}

variable "project" {
  description = "Project slug used in resource names and tags."
  type        = string
  default     = "interstellar-co"
}

variable "website_bucket_name" {
  description = "Globally unique name for the staging website S3 bucket."
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class for staging."
  type        = string
  default     = "PriceClass_100"
}

variable "acm_certificate_arn" {
  description = "ACM cert ARN (us-east-1) for custom domain. Leave empty to use the default CloudFront cert."
  type        = string
  default     = ""
}

variable "domain_aliases" {
  description = "Custom domain aliases for CloudFront."
  type        = list(string)
  default     = []
}
