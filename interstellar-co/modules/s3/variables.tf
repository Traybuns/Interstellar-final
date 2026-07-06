# ── modules/s3/variables.tf ─────────────────────────────────
# Input variables for the S3 static-website-hosting module.

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev | staging | prod)."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "project" {
  description = "Project identifier used for tagging and resource naming."
  type        = string
  default     = "interstellar-co"
}

variable "cloudfront_distribution_arn" {
  description = <<-EOT
    ARN of the CloudFront distribution that is allowed to read from this bucket.
    Used to build the bucket policy that restricts access to CloudFront OAC only.
    Pass an empty string to skip the bucket-policy resource (useful during bootstrap
    when CloudFront does not exist yet).
  EOT
  type    = string
  default = ""
}

variable "tags" {
  description = "Additional tags to merge onto all resources."
  type        = map(string)
  default     = {}
}
