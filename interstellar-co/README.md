# Interstellar Co — Website Infrastructure

Static website hosted on AWS (S3 + CloudFront + OAC), with separate Terraform
workspaces for **dev**, **staging**, and **prod**.

---

## Project Structure

```
interstellar-co/
├── modules/
│   ├── s3/           Private S3 bucket (versioning, encryption, OAC policy)
│   ├── cloudfront/   CloudFront distribution (OAC, HTTPS, custom error pages)
│   └── iam/          Least-privilege CI/CD deploy role
├── environments/
│   ├── dev/          dev environment (cheapest price class, no custom domain)
│   ├── staging/      staging environment
│   └── prod/         prod environment (global CDN, requires ACM cert)
├── website/
│   ├── index.html    Static site
│   ├── styles.css
│   └── script.js
└── README.md
```

---

## Architecture

```
User → CloudFront (HTTPS, OAC) → Private S3 Bucket
                                       ↑
                           Bucket policy: allow only
                           this CloudFront distribution
```

- **S3** bucket is never directly public. `block_public_acls = true` and
  `restrict_public_buckets = true` are always set.
- **CloudFront OAC** signs every request to S3 with SigV4. The bucket policy
  uses `aws:SourceArn` to scope access to the specific distribution.
- **HTTPS enforced** via `viewer_protocol_policy = "redirect-to-https"`.
- **TLS 1.2+** (`TLSv1.2_2021` security policy).
- **DynamoDB** lock table per environment prevents concurrent `terraform apply`.
- **Remote state** stored encrypted in S3, separate bucket per environment.

---

## Prerequisites

1. AWS credentials configured (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
   or an IAM role via instance profile / OIDC).
2. Bootstrap the state backend for each environment **once** (before `terraform init`):

```bash
# Example bootstrap for dev (run once, manually or via a script)
aws s3api create-bucket \
  --bucket interstellar-co-tfstate-dev \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket interstellar-co-tfstate-dev \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket interstellar-co-tfstate-dev \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb create-table \
  --table-name interstellar-co-tflock-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

3. For **prod**: create an ACM certificate in `us-east-1` for your domain and
   validate it via DNS before applying.

---

## Usage

### Init (once per environment, or after provider changes)

```bash
cd environments/dev
terraform init -backend-config=backend.hcl
```

### Plan

```bash
terraform plan -var-file=terraform.tfvars
```

### Apply

```bash
terraform apply -var-file=terraform.tfvars
```

### Deploy website files

After `terraform apply`, upload the website to S3 and invalidate the cache:

```bash
# Get outputs
BUCKET=$(terraform output -raw website_bucket_name)
CF_ID=$(terraform output -raw cloudfront_distribution_id)

# Sync website files
aws s3 sync ../../website/ s3://${BUCKET}/ \
  --delete \
  --cache-control "max-age=86400"

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id ${CF_ID} \
  --paths "/*"
```

---

## Environment Differences

| Setting              | dev             | staging         | prod              |
|----------------------|-----------------|-----------------|-------------------|
| Price class          | PriceClass_100  | PriceClass_100  | PriceClass_All    |
| Custom domain / ACM  | No              | Optional        | Required          |
| force_destroy on S3  | true            | true            | false             |
| CloudFront HTTP ver  | http2and3       | http2and3       | http2and3         |

---

## Tagging Convention

All resources are tagged with:

| Tag           | Value                          |
|---------------|--------------------------------|
| `Environment` | `dev` / `staging` / `prod`     |
| `Project`     | `interstellar-co`              |
| `ManagedBy`   | `terraform`                    |

---

## Security Notes

- S3 buckets are **never public** — all public-access blocks are enabled.
- The CloudFront OAC uses **SigV4** signing (not the legacy OAI mechanism).
- The bucket policy uses `aws:SourceArn` to prevent confused-deputy attacks.
- IAM deploy roles follow **least privilege** — only `s3:PutObject`,
  `s3:DeleteObject`, `s3:ListBucket`, and `cloudfront:CreateInvalidation`.
- State files are **encrypted at rest** (AES-256) in S3.
