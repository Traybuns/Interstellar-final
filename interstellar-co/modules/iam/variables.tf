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
  description = "ARN of the website S3 bucket the deploy role must read/write."
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution the deploy role must create invalidations on."
  type        = string
}

variable "tf_state_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform state. The Terraform role needs read/write access."
  type        = string
}

# ── OIDC ───────────────────────────────────────────────────── #

variable "create_oidc_provider" {
  description = <<-EOT
    Whether to create the GitHub Actions OIDC provider in this AWS account.
    Set to true for the first environment bootstrapped in an account.
    Set to false for additional environments sharing the same account —
    the provider can only exist once per account; subsequent creates fail.
  EOT
  type    = bool
  default = true
}

variable "oidc_provider_arn" {
  description = <<-EOT
    ARN of an existing GitHub OIDC provider. Required when
    create_oidc_provider = false. Ignored otherwise.
  EOT
  type    = string
  default = ""
}

variable "github_oidc_subjects" {
  description = <<-EOT
    List of GitHub Actions OIDC subject claim values allowed to assume
    BOTH the deploy role and the Terraform role.

    Examples:
      - "repo:Traybuns/Interstellar-deployment:environment:dev"        (environment-scoped)
      - "repo:Traybuns/Interstellar-deployment:ref:refs/heads/main"    (branch-scoped)
      - "repo:Traybuns/Interstellar-deployment:*"                      (any workflow in repo)

    Use the most restrictive form that fits your workflow. Environment-scoped
    claims require GitHub environment protection rules to be configured.
  EOT
  type    = list(string)
  default = ["repo:Traybuns/Interstellar-deployment:*"]
}

variable "tags" {
  description = "Additional tags to merge onto all resources."
  type        = map(string)
  default     = {}
}
