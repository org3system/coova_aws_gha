# coova_aws_gha

GitHub Actions workflow to build a **CoovaChilli 1.8** RPM for CentOS 6 / EL6 using **AWS ECS Fargate** provisioned by **Terraform**.

Authentication with AWS uses **OpenID Connect (OIDC)** — no long-lived access keys are stored after the one-time bootstrap.

---

## Repository layout

```
.
├── .github/workflows/
│   ├── bootstrap.yml          # One-time setup workflow (run once, then never again)
│   └── build-rpm-ecs.yml      # Main CI workflow (runs on every push/PR to main)
├── docker/
│   └── Dockerfile             # CentOS 6 RPM build image
├── packaging/
│   └── coova-chilli.spec      # RPM spec file
├── scripts/
│   └── build-rpm-ecs.sh       # Entrypoint script run inside ECS container
└── terraform/
    ├── bootstrap/             # One-time state backend setup
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── main.tf                # Provider + S3 backend config
    ├── variables.tf
    ├── outputs.tf
    ├── backend.tf
    ├── ecr.tf                 # ECR repository
    ├── ecs.tf                 # ECS cluster + task definition + security group
    ├── iam.tf                 # Execution, task & OIDC IAM roles
    ├── oidc.tf                # GitHub Actions OIDC identity provider
    └── s3.tf                  # Artifacts S3 bucket
```

---

## First-time setup — Bootstrap (run once only)

> The bootstrap workflow uses **temporary static credentials** to create the AWS infrastructure,
> including the OIDC role. Once it completes, the static credentials must be deleted.
> All subsequent workflows authenticate via OIDC — no secrets required.

### Step 1 — Add required secrets and variables in GitHub

Go to **Settings → Secrets and variables → Actions**.

**Secrets** (temporary — delete after bootstrap):

| Secret | Description |
|--------|-------------|
| `AWS_BOOTSTRAP_ACCESS_KEY_ID` | Access key for a one-time bootstrap IAM user |
| `AWS_BOOTSTRAP_SECRET_ACCESS_KEY` | Secret key for the same IAM user |

**Variables** (must exist before running bootstrap):

| Variable | Example | Description |
|----------|---------|-------------|
| `SUBNET_IDS` | `["subnet-abc123","subnet-def456"]` | JSON list of subnet IDs for ECS tasks (need outbound internet) |
| `VPC_ID` | `vpc-0abc1234` | VPC ID for the ECS task security group |

### Step 2 — Run the bootstrap workflow

**From the GitHub UI:**
```
Actions → Bootstrap – Create Terraform State Backend → Run workflow
  state_bucket_name: <globally unique S3 bucket name>
  aws_region:        us-east-1  (or your preferred region)
```

**From the terminal using `gh` CLI:**
```bash
gh workflow run bootstrap.yml \
  --repo <owner>/<repo> \
  --field state_bucket_name=my-unique-tf-state-bucket \
  --field aws_region=us-east-1

# Watch progress
gh run watch --repo <owner>/<repo>
```

**What bootstrap does:**

```
1. Authenticates with static AWS credentials
2. terraform/bootstrap/ → creates S3 bucket (Terraform state) + DynamoDB table (state lock)
3. terraform/          → creates ECR, ECS cluster, S3 artifacts bucket,
                         IAM roles, and the GitHub Actions OIDC role (gha_deployer)
4. Prints TF_STATE_BUCKET and AWS_ROLE_ARN values to save as GitHub variables
```

### Step 3 — Save outputs as GitHub variables

After bootstrap completes, check the logs for the printed values and add them as **variables**:

| Variable | Where to get it |
|----------|-----------------|
| `TF_STATE_BUCKET` | The bucket name you provided during bootstrap |
| `AWS_ROLE_ARN` | Printed in the bootstrap job output logs |
| `AWS_REGION` | The region you used (defaults to `us-east-1`) |

### Step 4 — Delete the bootstrap secrets

> Leaving these secrets in GitHub is a security risk. Delete them immediately after bootstrap.

```
Settings → Secrets and variables → Actions → Secrets
  → Delete AWS_BOOTSTRAP_ACCESS_KEY_ID
  → Delete AWS_BOOTSTRAP_SECRET_ACCESS_KEY
```

Also delete the bootstrap IAM user in the AWS console — it is no longer needed.

---

## Main CI pipeline — build-rpm-ecs.yml

Triggers automatically on push or PR to `main`, or manually from the Actions tab.
Authenticates with AWS via **OIDC** — no secrets involved.

### Architecture

```
Push / PR to main
       │
       ▼
Job 1 — infra
  OIDC login to AWS
  terraform apply → ensures ECR, ECS, S3, IAM are up to date
  Captures outputs: ECR URL, cluster name, S3 bucket, subnets, security group
       │
       ▼
Job 2 — docker
  Builds docker/Dockerfile (CentOS 6 + build tools + AWS CLI)
  Tags image with commit SHA
  Pushes to ECR
       │
       ▼
Job 3 — build-rpm
  Registers new ECS task definition with the exact image just pushed
  Launches ECS Fargate task
  Waits up to 30 minutes

  Inside the container (scripts/build-rpm-ecs.sh):
    Downloads CoovaChilli 1.8 source tarball
    Installs build dependencies via yum-builddep
    Builds SRPM + binary RPM using packaging/coova-chilli.spec
    Uploads RPMs to S3

  Checks container exit code — fails pipeline if non-zero
       │
       ▼
Job 4 — publish
  Downloads RPMs from S3
  Uploads as GitHub Actions artifact: coova-chilli-centos6-rpms
  Creates or updates GitHub Release v1.8 with RPM files attached
```

### Triggering the build manually

**From GitHub UI:**
```
Actions → Build CoovaChilli 1.8 RPM (ECS Fargate) → Run workflow
```

**From the terminal:**
```bash
gh workflow run build-rpm-ecs.yml --repo <owner>/<repo>
```

---

## Variables reference

| Variable | Required before | Description |
|----------|----------------|-------------|
| `SUBNET_IDS` | Bootstrap | JSON list of subnet IDs for ECS tasks |
| `VPC_ID` | Bootstrap | VPC ID for the ECS task security group |
| `TF_STATE_BUCKET` | Main pipeline | S3 bucket name for Terraform remote state |
| `AWS_ROLE_ARN` | Main pipeline | IAM role ARN assumed via OIDC |
| `AWS_REGION` | Main pipeline | AWS region (defaults to `us-east-1` if unset) |

---

## Output

- RPMs available as GitHub Actions artifact `coova-chilli-centos6-rpms`
- RPMs published under GitHub Release `v1.8`
- RPMs persisted in S3 under `s3://<TF_STATE_BUCKET>/rpms/`
- Build logs in CloudWatch Logs under `/ecs/<cluster-name>`

---

## Security notes

- The main pipeline uses **OIDC** — GitHub exchanges a signed JWT for a short-lived AWS token at runtime. No credentials are stored anywhere.
- Static bootstrap credentials are **temporary** and must be deleted after the one-time setup.
- The OIDC role is scoped to this specific repository, preventing other repos from assuming it.
