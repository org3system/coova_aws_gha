# Inline policy attached to the bootstrap IAM user so it can run the main
# Terraform apply (Step 2 of the bootstrap workflow). The user only needs
# these permissions once – delete or disable the user after bootstrap succeeds.

data "aws_caller_identity" "bootstrap" {}

resource "aws_iam_user_policy" "bootstrap_permissions" {
  name = "bootstrap-main-terraform"
  user = var.bootstrap_iam_user

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ── IAM: create/tag roles and OIDC provider ──────────────────────────────
      {
        Sid    = "IAMManage"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:TagRole",       # was missing – caused AccessDenied on ecs_execution & ecs_task roles
          "iam:UntagRole",
          "iam:PassRole",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",  # was missing – caused AccessDenied on OIDC provider
          "iam:UntagOpenIDConnectProvider"
        ]
        Resource = ["*"]
      },
      # ── EC2: security group + tagging ────────────────────────────────────────
      {
        Sid    = "EC2VPCManage"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateTags",  # was missing – needed for tag-on-create on security groups
          "ec2:DeleteTags",
          "ec2:DescribeTags"
        ]
        Resource = ["*"]
      },
      # ── ECS ──────────────────────────────────────────────────────────────────
      {
        Sid    = "ECSManage"
        Effect = "Allow"
        Action = [
          "ecs:CreateCluster",
          "ecs:DeleteCluster",
          "ecs:DescribeClusters",
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTaskDefinitions",
          "ecs:RunTask",
          "ecs:DescribeTasks",
          "ecs:StopTask",
          "ecs:TagResource",
          "ecs:ListTagsForResource"
        ]
        Resource = ["*"]
      },
      # ── ECR ──────────────────────────────────────────────────────────────────
      {
        Sid    = "ECRManage"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:DescribeRepositories",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:ListTagsForResource",
          "ecr:TagResource"
        ]
        Resource = ["*"]
      },
      # ── S3: state bucket + artifacts bucket ──────────────────────────────────
      {
        Sid    = "S3Manage"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLogging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketPolicy",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket_name}",
          "arn:aws:s3:::${var.state_bucket_name}/*",
          "arn:aws:s3:::${var.project}-artifacts",
          "arn:aws:s3:::${var.project}-artifacts/*"
        ]
      },
      # ── DynamoDB: state lock table ────────────────────────────────────────────
      {
        Sid    = "DynamoDBStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.bootstrap.account_id}:table/${var.lock_table_name}"
      },
      # ── CloudWatch Logs ───────────────────────────────────────────────────────
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy",
          "logs:ListTagsLogGroup",
          "logs:TagLogGroup"
        ]
        Resource = ["*"]
      }
    ]
  })
}
