# ── environments/staging/terraform.tfvars ───────────────────

aws_region             = "us-east-1"
environment            = "staging"
project                = "interstellar-co"

website_bucket_name    = "interstellar-co-website-staging"

# Staging uses PriceClass_100 — wider than dev if needed, still cost-conscious.
cloudfront_price_class = "PriceClass_100"

# Add an ACM cert ARN here when you set up staging.interstellar.co
acm_certificate_arn    = ""
domain_aliases         = []
