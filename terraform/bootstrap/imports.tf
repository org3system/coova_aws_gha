# Import blocks for resources that may already exist from a previous bootstrap
# run. Terraform will adopt them into state instead of erroring on create.
# Safe to leave in place on a clean run — if the resource doesn't exist yet,
# Terraform simply creates it as normal.

import {
  to = aws_s3_bucket.tf_state
  id = var.state_bucket_name
}

import {
  to = aws_s3_bucket_versioning.tf_state
  id = var.state_bucket_name
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.tf_state
  id = var.state_bucket_name
}

import {
  to = aws_s3_bucket_public_access_block.tf_state
  id = var.state_bucket_name
}

import {
  to = aws_dynamodb_table.tf_lock
  id = var.lock_table_name
}

import {
  to = aws_iam_user_policy_attachment.bootstrap["iam"]
  id = "${var.bootstrap_iam_user}/arn:aws:iam::aws:policy/IAMFullAccess"
}

import {
  to = aws_iam_user_policy_attachment.bootstrap["ec2"]
  id = "${var.bootstrap_iam_user}/arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

import {
  to = aws_iam_user_policy_attachment.bootstrap["ecs"]
  id = "${var.bootstrap_iam_user}/arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

import {
  to = aws_iam_user_policy_attachment.bootstrap["ecr"]
  id = "${var.bootstrap_iam_user}/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

import {
  to = aws_iam_user_policy_attachment.bootstrap["s3"]
  id = "${var.bootstrap_iam_user}/arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

import {
  to = aws_iam_user_policy_attachment.bootstrap["dynamodb"]
  id = "${var.bootstrap_iam_user}/arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

import {
  to = aws_iam_user_policy_attachment.bootstrap["cloudwatch_logs"]
  id = "${var.bootstrap_iam_user}/arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
