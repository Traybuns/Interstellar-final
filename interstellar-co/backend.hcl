# ── interstellar-co/backend.hcl ─────────────────────────────
# Remote state configuration.
#
# Usage:
#   terraform init -backend-config=backend.hcl
#
# The S3 bucket and DynamoDB table below must exist BEFORE running init.
# Create them once manually (or via the bootstrap script in README.md):
#
#   aws s3api create-bucket \
#     --bucket interstellar-co-tfstate-dev \
#     --region eu-north-1 \
#     --create-bucket-configuration LocationConstraint=eu-north-1
#
#   aws s3api put-bucket-versioning \
#     --bucket interstellar-co-tfstate-dev \
#     --versioning-configuration Status=Enabled
#
#   aws dynamodb create-table \
#     --table-name interstellar-co-tflock-dev \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST \
#     --region eu-north-1

bucket         = "interstellar-co-tfstate-dev"
key            = "terraform.tfstate"
region         = "eu-north-1"
encrypt        = true
dynamodb_table = "interstellar-co-tflock-dev"
