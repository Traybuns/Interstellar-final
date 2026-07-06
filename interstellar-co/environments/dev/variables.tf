# ── environments/dev/variables.tf ───────────────────────────

variable "aws_region" {
  description = "Primary AWS region for dev resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name — always 'dev' for this directory."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project slug used in resource names and tags."
  type        = string
  default     = "interstellar-co"
}

variable "website_bucket_name" {
  description = "Globally unique name for the dev website S3 bucket."
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class. Dev uses PriceClass_100 to minimise cost."
  type        = string
  default     = "PriceClass_100"
}

variable "acm_certificate_arn" {
  description = "ACM cert ARN (us-east-1) for custom domain. Leave empty to use the default CloudFront cert."
  type        = string
  default     = ""
}

variable "domain_aliases" {
  description = "Custom domain aliases for CloudFront. Leave empty when using the default *.cloudfront.net domain."
  type        = list(string)
  default     = []
}
