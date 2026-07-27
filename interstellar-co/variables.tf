# ── interstellar-co/variables.tf ────────────────────────────

variable "aws_region" {
  description = "Primary AWS region where website resources are deployed."
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name. Fixed to 'dev' for this repo."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project slug used in resource names and tags."
  type        = string
  default     = "interstellar-co"
}

variable "website_bucket_name" {
  description = "Globally unique name for the website S3 bucket."
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class. PriceClass_100 = US + Europe (cheapest)."
  type        = string
  default     = "PriceClass_100"
}

variable "acm_certificate_arn" {
  description = <<-EOT
    ACM certificate ARN (must be in us-east-1) for a custom domain.
    Leave empty to use the free default *.cloudfront.net certificate.
  EOT
  type    = string
  default = ""
}

variable "domain_aliases" {
  description = "Custom domain aliases for CloudFront. Leave empty when using *.cloudfront.net."
  type        = list(string)
  default     = []
}

variable "tf_state_bucket_name" {
  description = "Name of the S3 bucket that holds this Terraform state."
  type        = string
}

variable "create_oidc_provider" {
  description = <<-EOT
    Whether to create the GitHub Actions OIDC identity provider in this AWS account.
    Only one provider can exist per account — set false if it was already created
    by a previous Terraform run and the account hasn't been reset.
  EOT
  type    = bool
  default = true
}

variable "github_oidc_subjects" {
  description = <<-EOT
    OIDC subject claim values that may assume the deploy and Terraform roles.
    Default allows any workflow in the Interstellar-deployment repo.
    Tighten this to environment: or branch: scoped values for stricter control.
  EOT
  type    = list(string)
  default = ["repo:Traybuns/Interstellar-deployment:*"]
}
