# ── environments/prod/backend.hcl ───────────────────────────

bucket         = "interstellar-co-tfstate-prod"
key            = "environments/prod/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "interstellar-co-tflock-prod"
