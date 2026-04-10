variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project tag applied to bootstrap resources"
  type        = string
  default     = "coova-chilli-builder"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9\\-]{1,61}[a-z0-9]$", var.state_bucket_name)) && !can(regex("\\.\\.", var.state_bucket_name))
    error_message = "state_bucket_name must be 3–63 characters, lowercase letters/numbers/hyphens, start and end with a letter or number, and contain no consecutive hyphens."
  }
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "bootstrap_iam_user" {
  description = "IAM username of the one-time bootstrap user (AWS_BOOTSTRAP_ACCESS_KEY_ID owner). Used only for the pre-flight policy check in the GitHub Actions workflow — not managed by Terraform."
  type        = string
  default     = "iam-coova-ec-bs"
  validation {
    condition     = length(var.bootstrap_iam_user) > 0
    error_message = "bootstrap_iam_user must not be empty."
  }
}
