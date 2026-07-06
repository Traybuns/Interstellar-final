# ── environments/prod/terraform.tfvars ──────────────────────
# IMPORTANT: acm_certificate_arn MUST be set before applying prod.
# Create the certificate in ACM (us-east-1), validate it via DNS, then
# paste the ARN here. Do NOT commit the ARN if your repo is public;
# use TF_VAR_acm_certificate_arn env var instead.

aws_region             = "us-east-1"
environment            = "prod"
project                = "interstellar-co"

website_bucket_name    = "interstellar-co-website-prod"

# PriceClass_All — all CloudFront edge locations globally for best performance.
cloudfront_price_class = "PriceClass_All"

# Set these when your domain is ready:
# acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# domain_aliases      = ["interstellar.co", "www.interstellar.co"]
