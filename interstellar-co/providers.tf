# ── interstellar-co/providers.tf ────────────────────────────
# Provider configuration for the dev environment.
#
# CloudFront distributions are global, but their ACM certificates MUST
# be provisioned in us-east-1. Because this project deploys resources in
# eu-north-1 we need two provider aliases so Terraform knows which region
# to call for each resource type.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in S3 — configured via backend.hcl at init time.
  # Run: terraform init -backend-config=backend.hcl
  backend "s3" {}
}

# ── Default provider — primary deployment region ──────────── #
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

# ── Alias provider — us-east-1 required by CloudFront + ACM ── #
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
