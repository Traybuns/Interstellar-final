# ── modules/cloudfront/variables.tf ─────────────────────────

variable "environment" {
  description = "Deployment environment (dev | staging | prod)."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "project" {
  description = "Project identifier used for tagging and naming."
  type        = string
  default     = "interstellar-co"
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the origin S3 bucket (from the s3 module output)."
  type        = string
}

variable "s3_bucket_id" {
  description = "ID (name) of the origin S3 bucket, used when naming the OAC."
  type        = string
}

variable "acm_certificate_arn" {
  description = <<-EOT
    ARN of the ACM certificate to use for HTTPS.
    Must be in us-east-1 (CloudFront requirement).
    Leave empty to fall back to the default CloudFront certificate (*.cloudfront.net).
  EOT
  type    = string
  default = ""
}

variable "aliases" {
  description = "Custom domain name aliases (e.g. [\"www.interstellar.co\"]). Leave empty to use the default CloudFront domain."
  type        = list(string)
  default     = []
}

variable "default_root_object" {
  description = "Default root object served when the root URL is requested."
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = <<-EOT
    CloudFront price class controlling which edge locations serve content.
    PriceClass_100  — US, Canada, Europe (cheapest)
    PriceClass_200  — US, Canada, Europe, Asia, Middle East, Africa
    PriceClass_All  — All locations (best performance, highest cost)
  EOT
  type    = string
  default = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "tags" {
  description = "Additional tags to merge onto all resources."
  type        = map(string)
  default     = {}
}
