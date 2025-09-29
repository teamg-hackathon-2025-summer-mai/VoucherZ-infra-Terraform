resource "aws_ecs_cluster" "main" {
  name = "${var.project_prefix}-ecs-cluster"
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_task_execution" {
  name = "${var.project_prefix}-ecs-task-execution-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution.arn
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.project_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_ecs_task_definition" "web" {
  family = "${var.project_prefix}-task-definition-web"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name = "web",
      image = "${aws_ecr_repository.web.repository_url}:${var.web_image_tag}",
      essential = true,

      portMappings = [
        {
          containerPort = 80,
          protocol = "tcp",
          name = "web",
          appProtocol = "http"
        }
      ],

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group = aws_cloudwatch_log_group.web.name,
          awslogs-region = "ap-northeast-1",
          awslogs-stream-prefix = "web"
        }
      },
    }
  ])
}

resource "aws_ecs_task_definition" "app" {
  family = "${var.project_prefix}-task-definition--app"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name = "app",
      image = "${aws_ecr_repository.app.repository_url}:${var.app_image_tag}",
      essential = true,
      portMappings = [
        {
          containerPort = 8000,
          protocol = "tcp",
          name = "app"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group = aws_cloudwatch_log_group.app.name,
          awslogs-region = "ap-northeast-1",
          awslogs-stream-prefix = "app"
        }
      },
      environment = [
        {
          name = "DB_NAME",
          value = var.rds_db_name
        }
      ]
      secrets = [
        {
          name = "DB_USERNAME",
          valueFrom = "${aws_db_instance.rds.master_user_secret[0].secret_arn}:username::"
        },
        {
          name = "DB_PASSWORD",
          valueFrom = "${aws_db_instance.rds.master_user_secret[0].secret_arn}:password::"
        },
        {
          name = "DB_HOST",
          valueFrom = "${aws_db_instance.rds.master_user_secret[0].secret_arn}:host::"
        },
        {
          name = "DB_PORT",
          valueFrom = "${aws_db_instance.rds.master_user_secret[0].secret_arn}:port::"
        },
        {
          name = "DJANGO_ALLOWED_HOSTS",
          valueFrom = local.ssm_param_paths.DJANGO_ALLOWED_HOSTS
        },
        {
          name = "DJANGO_ENV",
          valueFrom = local.ssm_param_paths.DJANGO_ENV
        },
        {
          name = "DJANGO_SECRET_KEY",
          valueFrom = local.ssm_param_paths.DJANGO_SECRET_KEY
        },
      ]
    }
  ])
}

resource "aws_ecs_service" "web" {
  name = "${var.project_prefix}-ecs-service-web"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  launch_type = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.private["private_ap_northeast_1a_ecs"].id,
      aws_subnet.private["private_ap_northeast_1c_ecs"].id
    ]
    security_groups = [aws_security_group.app_fargate.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_80.arn
    container_name = "web"
    container_port = 80
  }

  depends_on = [
    aws_lb_listener.http_80_redirect,
    aws_lb_listener.https_443
  ]
}

resource "aws_ecs_service" "app" {
  name = "${var.project_prefix}-ecs-service-app"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = 1
  launch_type = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets = [
      aws_subnet.private["private_ap_northeast_1a_ecs"].id,
      aws_subnet.private["private_ap_northeast_1c_ecs"].id
    ]
    security_groups = [aws_security_group.app_fargate.id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.app.arn
    service {
      port_name = "app"
      client_alias {
        dns_name = "app"
        port = 8000
      }
    }
  }
}

resource "aws_service_discovery_private_dns_namespace" "app" {
  name = "service.local"
  vpc  = aws_vpc.main.id
}