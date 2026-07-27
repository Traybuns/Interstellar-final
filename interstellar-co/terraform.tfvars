# ── interstellar-co/terraform.tfvars ────────────────────────
# Variable values for the dev environment.
# Safe to commit — no secrets live here. Sensitive values (role ARNs
# produced after first apply, ACM cert ARNs) are passed via GitHub
# Secrets and referenced as TF_VAR_* env vars in CI when needed.

aws_region             = "eu-north-1"
environment            = "dev"
project                = "interstellar-co"

# Bucket name must be globally unique across all of AWS.
website_bucket_name    = "interstellar-co-website-dev"

# PriceClass_100 = US + Europe edge locations. Lowest cost option.
cloudfront_price_class = "PriceClass_100"

# Custom domain: leave empty to use the free *.cloudfront.net certificate.
# To add a custom domain later, set these and re-apply:
#   acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
#   domain_aliases      = ["dev.interstellar.co"]
acm_certificate_arn    = ""
domain_aliases         = []

# Set to false after the first apply if the OIDC provider already exists
# in your AWS account from a previous run.
create_oidc_provider   = true

# Allow any workflow in this repo to assume the deploy and Terraform roles.
github_oidc_subjects   = ["repo:Traybuns/Interstellar-final:*"]
