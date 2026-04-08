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
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "bootstrap_iam_user" {
  description = "IAM username of the one-time bootstrap user (AWS_BOOTSTRAP_ACCESS_KEY_ID owner)"
  type        = string
  default     = "iam-coova-ec-bs"
}
