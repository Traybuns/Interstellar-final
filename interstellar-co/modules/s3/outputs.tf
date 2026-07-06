# ── modules/s3/outputs.tf ───────────────────────────────────

output "bucket_id" {
  description = "The name of the S3 bucket."
  value       = aws_s3_bucket.website.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.website.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name used as the CloudFront origin domain."
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}
