output "ecr_repository_url" {
  description = "ECR repository URL for the builder image"
  value       = aws_ecr_repository.builder.repository_url
}

output "s3_bucket_name" {
  description = "S3 bucket where built RPMs are uploaded"
  value       = aws_s3_bucket.artifacts.bucket
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.builder.name
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN (latest revision)"
  value       = aws_ecs_task_definition.rpm_builder.arn
}

output "task_security_group_id" {
  description = "Security group ID attached to ECS Fargate tasks"
  value       = aws_security_group.ecs_task.id
}

output "gha_deployer_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC – set as the AWS_ROLE_ARN repository variable"
  value       = aws_iam_role.gha_deployer.arn
}
