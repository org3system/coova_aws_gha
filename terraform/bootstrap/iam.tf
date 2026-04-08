# Attach AWS managed policies to the bootstrap IAM user so it can run the
# main Terraform apply (Step 2 of the bootstrap workflow). The user only
# needs these permissions once – delete or disable it after bootstrap succeeds.

locals {
  bootstrap_managed_policies = {
    iam            = "arn:aws:iam::aws:policy/IAMFullAccess"
    ec2            = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
    ecs            = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
    ecr            = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
    s3             = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    dynamodb       = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    cloudwatch_logs = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }
}

resource "aws_iam_user_policy_attachment" "bootstrap" {
  for_each   = local.bootstrap_managed_policies
  user       = var.bootstrap_iam_user
  policy_arn = each.value
}
