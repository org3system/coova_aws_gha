terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # No remote backend block here — state is stored locally on the runner.
  # This is intentional: this module creates the remote backend itself, so it
  # can't use it yet. All other Terraform modules use the bucket created here.
}

# Target AWS region is passed in as a variable (defaults to us-east-1).
provider "aws" {
  region = var.aws_region
}

# ── S3 state bucket ──────────────────────────────────────────────────────────

# The bucket that will store .tfstate files for every other Terraform module
# in this repo. The name must be globally unique across all AWS accounts.
resource "aws_s3_bucket" "tf_state" {
  bucket = var.state_bucket_name
  tags   = { Project = var.project }
}

# Keep every version of each state file so you can roll back to a previous
# state if an apply goes wrong or state corruption occurs.
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state files at rest using AES-256 (SSE-S3).
# State files can contain sensitive values, so encryption is mandatory.
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Ensure the state bucket is never publicly accessible, regardless of any
# account-level or bucket-level ACL settings that might be applied later.
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true  # reject requests that include a public ACL
  block_public_policy     = true  # reject bucket policies that grant public access
  ignore_public_acls      = true  # ignore any existing public ACLs on objects
  restrict_public_buckets = true  # block all cross-account public access
}

# ── DynamoDB lock table ──────────────────────────────────────────────────────

# Terraform uses this table to implement state locking: before any apply,
# Terraform writes a record here so that two concurrent runs can't corrupt the
# same state file. The hash key "LockID" is the fixed key Terraform expects.
resource "aws_dynamodb_table" "tf_lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST" # no capacity planning needed; lock ops are infrequent
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S" # string — Terraform writes the backend bucket+key as the lock ID
  }

  tags = { Project = var.project }
}
