# ── modules/cloudfront/outputs.tf ──────────────────────────

output "distribution_id" {
  description = "The ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.website.id
}

output "distribution_arn" {
  description = "The ARN of the CloudFront distribution. Pass this to the S3 module to build the bucket policy."
  value       = aws_cloudfront_distribution.website.arn
}

output "distribution_domain_name" {
  description = "The domain name assigned to the CloudFront distribution (e.g. d1234.cloudfront.net)."
  value       = aws_cloudfront_distribution.website.domain_name
}

output "oac_id" {
  description = "The ID of the Origin Access Control."
  value       = aws_cloudfront_origin_access_control.website.id
}
