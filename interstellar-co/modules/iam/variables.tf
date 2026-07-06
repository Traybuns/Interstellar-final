# ── modules/iam/variables.tf ────────────────────────────────

variable "environment" {
  description = "Deployment environment (dev | staging | prod)."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "project" {
  description = "Project identifier used for role and policy naming."
  type        = string
  default     = "interstellar-co"
}

variable "s3_bucket_arn" {
  description = "ARN of the website S3 bucket the deploy role must be able to read/write."
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution the deploy role must be able to create invalidations on."
  type        = string
}

variable "trusted_account_ids" {
  description = <<-EOT
    List of AWS account IDs allowed to assume the deploy role.
    Typically the account running your CI/CD pipeline.
    Defaults to the current account (self-trust).
  EOT
  type    = list(string)
  default = []
}

variable "tags" {
  description = "Additional tags to merge onto all resources."
  type        = map(string)
  default     = {}
}
