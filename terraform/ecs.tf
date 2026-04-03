resource "aws_cloudwatch_log_group" "rpm_builder" {
  name              = "/ecs/${var.project}"
  retention_in_days = 7
  tags              = { Project = var.project }
}

resource "aws_ecs_cluster" "builder" {
  name = var.project
  tags = { Project = var.project }
}

resource "aws_security_group" "ecs_task" {
  name        = "${var.project}-ecs-task"
  description = "Allow outbound internet access for ECS Fargate build task"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = var.project }
}

resource "aws_ecs_task_definition" "rpm_builder" {
  family                   = "${var.project}-rpm-builder"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "rpm-builder"
    image     = "${aws_ecr_repository.builder.repository_url}:${var.ecr_image_tag}"
    essential = true

    environment = [
      { name = "S3_BUCKET", value = aws_s3_bucket.artifacts.bucket },
      { name = "S3_PREFIX", value = var.s3_prefix }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.rpm_builder.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = { Project = var.project }
}
