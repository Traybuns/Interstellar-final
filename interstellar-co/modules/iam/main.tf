# ── modules/iam/main.tf ──────────────────────────────────────
# IAM resources for the CI/CD deployment pipeline.
#
# Two identities are provisioned:
#
#   deploy role  — least-privilege; S3 sync + CloudFront invalidation.
#                  Assumed by GitHub Actions workflows that deploy website
#                  files AFTER Terraform has already run.
#
#   terraform role — broader; can manage S3, CloudFront, IAM, DynamoDB,
#                    and ACM resources that make up the static-site stack.
#                    Assumed by GitHub Actions workflows that run
#                    terraform plan / terraform apply.
#
# Both roles use GitHub Actions OIDC for credential-free auth —
# no long-lived access keys are stored anywhere.

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
    },
    var.tags
  )

  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  deploy_role_name    = "${var.project}-${var.environment}-deploy"
  deploy_policy_name  = "${var.project}-${var.environment}-deploy-policy"
  tf_role_name        = "${var.project}-${var.environment}-terraform"
  tf_policy_name      = "${var.project}-${var.environment}-terraform-policy"

  # GitHub OIDC subject claim.
  # Format: repo:<owner>/<repo>:environment:<env>
  # Falls back to repo:<owner>/<repo>:ref:refs/heads/<branch> if no env name set.
  github_oidc_subjects = var.github_oidc_subjects
  oidc_provider_arn    = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.oidc_provider_arn
}

# ── GitHub Actions OIDC Identity Provider ─────────────────── #
# Create once per AWS account (not per environment). Set
# var.create_oidc_provider = false in environments that share an account
# with dev and already have the provider created.

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint — this is the SHA-1 of the root CA cert
  # for token.actions.githubusercontent.com. GitHub publishes this value.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  tags = local.common_tags
}

# ── OIDC Trust Policy (shared shape) ─────────────────────────── #
data "aws_iam_policy_document" "github_oidc_assume" {
  statement {
    sid     = "AllowGitHubOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_oidc_subjects
    }
  }
}

# ── Deploy Role ────────────────────────────────────────────── #
# Least-privilege: S3 website sync + CloudFront cache invalidation.
# Used by the deploy step AFTER terraform apply succeeds.

resource "aws_iam_role" "deploy" {
  name               = local.deploy_role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume.json
  description        = "GitHub Actions deploy role for ${var.project} ${var.environment} (OIDC)"

  tags = local.common_tags
}

data "aws_iam_policy_document" "deploy" {
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

  statement {
    sid     = "CloudFrontInvalidate"
    effect  = "Allow"
    actions = ["cloudfront:CreateInvalidation"]
    resources = [var.cloudfront_distribution_arn]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = local.deploy_policy_name
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}

# ── Terraform Role ─────────────────────────────────────────── #
# Broader permissions needed to run terraform plan/apply for the
# static-site stack (S3, CloudFront, IAM, DynamoDB, ACM).
# This role is separate from the deploy role so least-privilege is
# maintained for non-Terraform CI steps.

resource "aws_iam_role" "terraform" {
  name               = local.tf_role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume.json
  description        = "GitHub Actions Terraform role for ${var.project} ${var.environment} (OIDC)"

  tags = local.common_tags
}

data "aws_iam_policy_document" "terraform" {
  # S3 — website bucket + Terraform state bucket
  statement {
    sid    = "S3StaticSiteManage"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketPolicy",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:PutBucketAcl",
      "s3:PutBucketCORS",
      "s3:PutBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketTagging",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
    ]
    resources = [
      var.s3_bucket_arn,
      var.tf_state_bucket_arn,
    ]
  }

  statement {
    sid    = "S3StateObjects"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${var.s3_bucket_arn}/*",
      "${var.tf_state_bucket_arn}/*",
    ]
  }

  # DynamoDB — state lock table
  statement {
    sid    = "DynamoDBStateLock"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:GetItem",
      "dynamodb:ListTagsOfResource",
      "dynamodb:PutItem",
      "dynamodb:TagResource",
      "dynamodb:UpdateContinuousBackups",
      "dynamodb:UpdateTable",
    ]
    resources = [
      "arn:${local.partition}:dynamodb:*:${local.account_id}:table/interstellar-co-tflock-${var.environment}",
    ]
  }

  # CloudFront — distribution management
  statement {
    sid    = "CloudFrontManage"
    effect = "Allow"
    actions = [
      "cloudfront:CreateDistribution",
      "cloudfront:CreateInvalidation",
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:DeleteDistribution",
      "cloudfront:DeleteOriginAccessControl",
      "cloudfront:GetDistribution",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:ListDistributions",
      "cloudfront:ListTagsForResource",
      "cloudfront:TagResource",
      "cloudfront:UntagResource",
      "cloudfront:UpdateDistribution",
      "cloudfront:UpdateOriginAccessControl",
    ]
    resources = ["*"]
  }

  # IAM — manage the deploy and terraform roles/policies themselves
  # Scoped to resources this project owns by name prefix.
  statement {
    sid    = "IAMManageDeployRoles"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateOpenIDConnectProvider",
      "iam:CreateRole",
      "iam:CreateRolePolicy",
      "iam:DeleteOpenIDConnectProvider",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetOpenIDConnectProvider",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:TagOpenIDConnectProvider",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
    ]
    resources = [
      "arn:${local.partition}:iam::${local.account_id}:role/${var.project}-${var.environment}-*",
      "arn:${local.partition}:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com",
    ]
  }

  # ACM — read cert ARN for CloudFront (creation is manual / out-of-band)
  statement {
    sid    = "ACMDescribeCerts"
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "terraform" {
  name   = local.tf_policy_name
  role   = aws_iam_role.terraform.id
  policy = data.aws_iam_policy_document.terraform.json
}
