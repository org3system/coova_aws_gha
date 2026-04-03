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

## Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM access key with ECR, ECS, S3, IAM, CloudWatch permissions |
| `AWS_SECRET_ACCESS_KEY` | Corresponding secret key |

## Required GitHub Variables (repository-level)

| Variable | Example | Description |
|----------|---------|-------------|
| `AWS_REGION` | `us-east-1` | AWS region (defaults to `us-east-1` if unset) |
| `SUBNET_IDS` | `["subnet-abc123","subnet-def456"]` | JSON list of subnet IDs for ECS tasks (need outbound internet) |
| `VPC_ID` | `vpc-0123456789abcdef0` | VPC ID for the ECS task security group |

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
