variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name prefix used for all resource names"
  type        = string
  default     = "coova-chilli-builder"
}

variable "s3_prefix" {
  description = "S3 key prefix under which built RPMs are stored"
  type        = string
  default     = "rpms"
}

variable "ecr_image_tag" {
  description = "Docker image tag to use for the ECS task"
  type        = string
  default     = "latest"
}

variable "subnet_ids" {
  description = "List of subnet IDs where the Fargate task will run (must have internet access)"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID used for the ECS task security group"
  type        = string
}

variable "tf_state_bucket" {
  description = "S3 bucket name for Terraform remote state (created by terraform/bootstrap)"
  type        = string
}
