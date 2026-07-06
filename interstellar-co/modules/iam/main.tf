# ── modules/iam/main.tf ──────────────────────────────────────
# Least-privilege IAM role for the CI/CD deployment pipeline.
#
# The role grants only what is needed to deploy the static website:
#   • s3:PutObject / s3:DeleteObject on the website bucket      (sync)
#   • s3:ListBucket                                              (sync --delete)
#   • cloudfront:CreateInvalidation                              (cache bust)
#
# No console/GUI permissions are included — this is a machine identity.

data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # Accounts that may assume this role. Defaults to the current account.
  trusted_accounts = length(var.trusted_account_ids) > 0 ? var.trusted_account_ids : [data.aws_caller_identity.current.account_id]

  role_name   = "${var.project}-${var.environment}-deploy"
  policy_name = "${var.project}-${var.environment}-deploy-policy"
}

# ── Assume-role trust policy ──────────────────────────────── #
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "AllowAssumeFromTrustedAccounts"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [for acct in local.trusted_accounts : "arn:aws:iam::${acct}:root"]
    }
  }
}

# ── IAM Role ─────────────────────────────────────────────── #
resource "aws_iam_role" "deploy" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  description        = "CI/CD deploy role for ${var.project} ${var.environment}"

  tags = local.common_tags
}

# ── Inline permission policy ──────────────────────────────── #
data "aws_iam_policy_document" "deploy" {
  # S3: sync website files
  statement {
    sid    = "S3WebsiteSync"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject",
      "s3:GetObject",
    ]
    resources = ["${var.s3_bucket_arn}/*"]
  }

  statement {
    sid       = "S3ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.s3_bucket_arn]
  }

  # CloudFront: invalidate after deploy
  statement {
    sid     = "CloudFrontInvalidate"
    effect  = "Allow"
    actions = ["cloudfront:CreateInvalidation"]
    resources = [var.cloudfront_distribution_arn]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = local.policy_name
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}
