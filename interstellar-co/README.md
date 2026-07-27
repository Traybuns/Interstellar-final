# Interstellar Co — Infrastructure

Static website hosted on AWS via S3 + CloudFront, deployed automatically from GitHub Actions using OIDC (no long-lived access keys).

## Architecture

```
GitHub Actions (OIDC)
       |
       +-- Terraform role --> terraform plan/apply
       |
       +-- Deploy role -----> S3 sync + CloudFront invalidation
                                         |
                               CloudFront (OAC, HTTPS)
                                         |
                                  S3 bucket (private)
                                  website files
```

- S3 bucket is private — all public-access blocks enabled.
- CloudFront OAC signs every request to S3 with SigV4.
- Bucket policy scoped to the specific distribution ARN via `aws:SourceArn`.
- HTTPS enforced; TLS 1.2+ minimum.
- No AWS access keys stored anywhere — GitHub Actions uses OIDC.

## Repository structure

```
interstellar-co/
  main.tf              Root module — wires together S3, CloudFront, IAM
  providers.tf         AWS provider config (eu-north-1 + us-east-1 alias for CF/ACM)
  variables.tf         Input variable declarations
  terraform.tfvars     Non-secret variable values (safe to commit)
  backend.hcl          Remote state config — passed to terraform init
  modules/
    s3/                Private website bucket + OAC bucket policy
    cloudfront/        CloudFront distribution with OAC origin
    iam/               OIDC deploy role + Terraform role
  website/
    index.html
    styles.css
    script.js

.github/workflows/
  deploy.yml           Push to main → terraform apply → S3 sync → CF invalidation
  plan-pr.yml          Pull request → terraform plan (no apply)
  _terraform.yml       Reusable: init, validate, plan, apply
  _deploy.yml          Reusable: S3 sync + CF invalidation
```

## First-time bootstrap

Do this once, before the first GitHub Actions run.

### 1. Create the S3 state bucket

```bash
aws s3api create-bucket \
  --bucket interstellar-co-tfstate-dev \
  --region eu-north-1 \
  --create-bucket-configuration LocationConstraint=eu-north-1

aws s3api put-bucket-versioning \
  --bucket interstellar-co-tfstate-dev \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket interstellar-co-tfstate-dev \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

### 2. Create the DynamoDB lock table

```bash
aws dynamodb create-table \
  --table-name interstellar-co-tflock-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-north-1
```

### 3. Run the first Terraform apply locally

```bash
cd interstellar-co
terraform init -backend-config=backend.hcl
terraform plan -var="tf_state_bucket_name=interstellar-co-tfstate-dev"
terraform apply -var="tf_state_bucket_name=interstellar-co-tfstate-dev"
```

### 4. Capture role ARNs from outputs

```bash
terraform output terraform_role_arn
terraform output deploy_role_arn
```

### 5. Add GitHub Actions secrets

In repo **Settings > Secrets and variables > Actions**, add these four secrets:

| Secret name        | Where to get the value                              |
|--------------------|-----------------------------------------------------|
| `TF_ROLE_ARN`      | `terraform output terraform_role_arn`               |
| `DEPLOY_ROLE_ARN`  | `terraform output deploy_role_arn`                  |
| `TF_STATE_BUCKET`  | `interstellar-co-tfstate-dev`                       |
| `TF_LOCK_TABLE`    | `interstellar-co-tflock-dev`                        |

### 6. Create the GitHub environment

In repo **Settings > Environments**, create an environment named `dev`.
No protection rules are required — the workflow deploys automatically on push to `main`.

### 7. Push and verify

Push any change to `main`. The `Deploy` workflow will:
1. Run `terraform apply` (creates/updates infrastructure)
2. Sync website files to S3
3. Invalidate the CloudFront cache

The live URL is in the Terraform outputs:
```bash
terraform output cloudfront_domain
```

## Ongoing deployments

- **Push to `main`** → full deploy pipeline runs automatically
- **Open a PR** → `terraform plan` runs and uploads the plan as a workflow artifact (no apply)

## Notes on OIDC provider

The GitHub Actions OIDC identity provider is created once per AWS account by `module.iam` (`create_oidc_provider = true`). If you see `EntityAlreadyExists` on a fresh apply (provider was created by a previous run), set `create_oidc_provider = false` in `terraform.tfvars` and re-apply — it will skip creating the provider and reference the existing one.
