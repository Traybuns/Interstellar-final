# ── environments/dev/terraform.tfvars ───────────────────────
# Environment-specific variable values for dev.
# IMPORTANT: This file may be committed — do NOT put secrets here.
# Sensitive values (ACM cert ARNs tied to domain ownership) should be
# stored in a secrets manager or passed via TF_VAR_* env vars in CI.

aws_region             = "us-east-1"
environment            = "dev"
project                = "interstellar-co"

# Bucket name must be globally unique — adjust to your org's naming convention.
website_bucket_name    = "interstellar-co-website-dev"

# PriceClass_100 = US + Europe only. Cheapest option — ideal for dev/internal use.
cloudfront_price_class = "PriceClass_100"

# Leave empty to use the free default *.cloudfront.net certificate in dev.
acm_certificate_arn    = ""
domain_aliases         = []
