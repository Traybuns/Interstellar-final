# ── environments/dev/backend.hcl ────────────────────────────
# Remote state configuration for the dev environment.
#
# Usage:
#   terraform init -backend-config=backend.hcl
#
# The backend bucket and DynamoDB lock table are pre-provisioned manually
# (or via a bootstrap script) before running terraform init for the first time.
# They intentionally live OUTSIDE of this module's state to avoid the
# chicken-and-egg problem.

bucket         = "interstellar-co-tfstate-dev"
key            = "environments/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "interstellar-co-tflock-dev"
