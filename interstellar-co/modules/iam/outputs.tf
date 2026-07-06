# ── modules/iam/outputs.tf ──────────────────────────────────

output "deploy_role_arn" {
  description = "ARN of the CI/CD deploy role. Grant this to your pipeline's identity."
  value       = aws_iam_role.deploy.arn
}

output "deploy_role_name" {
  description = "Name of the CI/CD deploy role."
  value       = aws_iam_role.deploy.name
}
