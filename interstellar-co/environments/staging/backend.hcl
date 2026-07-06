# ── environments/staging/backend.hcl ────────────────────────

bucket         = "interstellar-co-tfstate-staging"
key            = "environments/staging/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "interstellar-co-tflock-staging"
