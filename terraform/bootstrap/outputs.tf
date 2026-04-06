output "state_bucket_name" {
  description = "S3 bucket name to set as TF_STATE_BUCKET GitHub Actions variable"
  value       = aws_s3_bucket.tf_state.bucket
}

output "lock_table_name" {
  description = "DynamoDB table name used for state locking"
  value       = aws_dynamodb_table.tf_lock.name
}
