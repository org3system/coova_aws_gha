data "aws_iam_policy_document" "gha_oidc_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Scope to this repo only; allow all branches/events
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:org3system/coova_aws_gha:*"]
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint (stable – rotate only when GitHub rotates their CA)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = { Project = var.project }
}

resource "aws_iam_role" "gha_deployer" {
  name               = "${var.project}-gha-deployer"
  assume_role_policy = data.aws_iam_policy_document.gha_oidc_assume.json
  tags               = { Project = var.project }
}

# ── Managed policy attachments ────────────────────────────────────────────────

# ECR push/pull and standard registry operations
resource "aws_iam_role_policy_attachment" "gha_deployer_ecr" {
  role       = aws_iam_role.gha_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# CloudWatch Logs – create/delete log groups, put retention policies, etc.
resource "aws_iam_role_policy_attachment" "gha_deployer_cloudwatch_logs" {
  role       = aws_iam_role.gha_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# ── Custom inline policy for permissions without a suitable managed equivalent ─

resource "aws_iam_role_policy" "gha_deployer_custom" {
  name = "deployer-custom-permissions"
  role = aws_iam_role.gha_deployer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ── ECR repository management (not covered by ECRPowerUser) ───────────────
      {
        Sid    = "ECRRepoManage"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:ListTagsForResource",
          "ecr:TagResource"
        ]
        Resource = [aws_ecr_repository.builder.arn]
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
      # ── IAM PassRole (so GHA can pass execution & task roles to ECS) ─────────
      {
        Sid    = "IAMPassRole"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.ecs_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
      },
      # ── IAM manage (Terraform creates/updates roles and OIDC provider) ────────
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
          "iam:TagRole",
          "iam:UntagRole",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider"
        ]
        Resource = ["*"]
      },
      # ── S3 artifacts bucket (scoped to specific bucket) ───────────────────────
      {
        Sid    = "S3Artifacts"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging",
          "s3:ListBucket",
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
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      # ── EC2 (VPC/SG management needed by Terraform) ───────────────────────────
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
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeTags"
        ]
        Resource = ["*"]
      }
    ]
  })
}
