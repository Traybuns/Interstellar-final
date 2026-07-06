# ── environments/dev/providers.tf ───────────────────────────
# Provider pins for the dev environment.
# CloudFront ACM certificates MUST be issued in us-east-1 — the `aws.us_east_1`
# alias provider is passed to any module that creates or references a cert.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default provider — deploy target region (change as needed)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "interstellar-co"
      ManagedBy   = "terraform"
    }
  }
}

# Alias provider for us-east-1 (CloudFront + ACM requirement)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "interstellar-co"
      ManagedBy   = "terraform"
    }
  }
}
