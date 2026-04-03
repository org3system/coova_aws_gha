# coova_aws_gha

GitHub Actions workflow to build a **CoovaChilli 1.8** RPM for CentOS 6 / EL6 using **AWS ECS Fargate** provisioned by **Terraform**.

---

## Architecture

```
GitHub Actions
  │
  ├── Job 1 – infra (Terraform)
  │     └── terraform apply → ECR repo, S3 bucket, ECS cluster, task definition, IAM roles
  │
  ├── Job 2 – docker
  │     └── Build CentOS 6 builder image → push to ECR
  │
  ├── Job 3 – build-rpm (ECS Fargate)
  │     └── aws ecs run-task → container builds RPM → uploads to S3
  │
  └── Job 4 – publish
        └── Download RPMs from S3 → upload as GHA artifact → GitHub Release
```

## Repository layout

```
.
├── .github/workflows/
│   └── build-rpm-ecs.yml      # Main CI workflow
├── docker/
│   └── Dockerfile             # CentOS 6 RPM build image
├── packaging/
│   └── coova-chilli.spec      # RPM spec (from coova_gha)
├── scripts/
│   └── build-rpm-ecs.sh       # Entrypoint script run inside ECS container
└── terraform/
    ├── main.tf                # Provider config
    ├── variables.tf
    ├── outputs.tf
    ├── ecr.tf                 # ECR repository
    ├── ecs.tf                 # ECS cluster + task definition + security group
    ├── iam.tf                 # Execution & task IAM roles
    └── s3.tf                  # Artifacts S3 bucket
```

## Required GitHub Variables (repository-level)

| Variable | Example | Description |
|----------|---------|-------------|
| `AWS_REGION` | `us-east-1` | AWS region (defaults to `us-east-1` if unset) |
| `AWS_ACCOUNT_ID` | `123456789012` | 12-digit AWS account ID used to build the OIDC role ARN |
| `SUBNET_IDS` | `["subnet-abc123","subnet-def456"]` | JSON list of subnet IDs for ECS tasks (need outbound internet) |
| `VPC_ID` | `vpc-0123456789abcdef0` | VPC ID for the ECS task security group |

## Setup GitHub OIDC with AWS

This workflow uses **OpenID Connect (OIDC)** to authenticate with AWS — no long-lived access keys are required.

### 1. Create an OIDC identity provider in AWS IAM

1. Open the [IAM console](https://console.aws.amazon.com/iam/) → **Identity providers** → **Add provider**.
2. Select **OpenID Connect**.
3. Provider URL: `https://token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`
5. Click **Add provider**.

### 2. Create the IAM role

Create a role named `github-actions-role` with the trust policy below, then attach the policies your workflow needs (ECR, ECS, S3, IAM read, CloudWatch Logs).

#### Trust policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<ORG>/<REPO>:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

Replace `<ACCOUNT_ID>` with your 12-digit AWS account ID.

> **Tip:** The `sub` condition above restricts role assumption to pushes on the `main` branch.
> Replace `<ORG>/<REPO>` with your actual GitHub organization and repository name (e.g. `org3system/coova_aws_gha`).
> To also allow pull requests, add a second entry:
> `"repo:<ORG>/<REPO>:pull_request"`.
> Avoid using a bare `*` wildcard, which would allow any branch or tag to assume the role.

### 3. Find your AWS account ID

```bash
aws sts get-caller-identity --query Account --output text
```

### 4. Add the GitHub repository variable

Add `AWS_ACCOUNT_ID` as a **repository variable** (not a secret) in  
**Settings → Secrets and variables → Actions → Variables → New repository variable**.

The workflow constructs the role ARN as:
```
arn:aws:iam::<AWS_ACCOUNT_ID>:role/github-actions-role
```

## Terraform state

By default Terraform uses a **local** state file. For production use, configure an S3 backend in `terraform/main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "my-tf-state-bucket"
    key    = "coova-chilli-builder/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Triggering the build

- Push to `main`
- Open a pull request
- Manually run **Build CoovaChilli 1.8 RPM (ECS Fargate)** from the Actions tab

## Output

- RPMs available as GitHub Actions artifact `coova-chilli-centos6-rpms`
- RPMs published under GitHub Release `v1.8`
- RPMs persisted in S3 under `s3://<bucket>/rpms/`
- Build logs in CloudWatch Logs under `/ecs/coova-chilli-builder`
