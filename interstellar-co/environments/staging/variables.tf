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

variable "tf_state_bucket_name" {
  description = "Name of the S3 bucket that holds Terraform state for this environment."
  type        = string
}

variable "create_oidc_provider" {
  description = "Create the GitHub Actions OIDC provider in this account. Set false if another env already created it."
  type        = bool
  default     = false
}

variable "github_oidc_subjects" {
  description = "OIDC subject claims allowed to assume the deploy and Terraform roles."
  type        = list(string)
  default     = ["repo:Traybuns/Interstellar-web:*"]
}
