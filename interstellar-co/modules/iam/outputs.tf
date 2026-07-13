# ── modules/iam/outputs.tf ──────────────────────────────────

output "deploy_role_arn" {
  description = "ARN of the deploy role. Used for S3 sync and CloudFront invalidation steps in GitHub Actions."
  value       = aws_iam_role.deploy.arn
}

output "deploy_role_name" {
  description = "Name of the deploy role."
  value       = aws_iam_role.deploy.name
}

output "terraform_role_arn" {
  description = "ARN of the Terraform role. Used for terraform plan/apply steps in GitHub Actions."
  value       = aws_iam_role.terraform.arn
}

output "terraform_role_name" {
  description = "Name of the Terraform role."
  value       = aws_iam_role.terraform.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider (whether created here or passed in)."
  value       = local.oidc_provider_arn
}
