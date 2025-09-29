resource "aws_cloudwatch_log_group" "web" {
  name = "/ecs/${var.project_prefix}/web"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "app" {
  name = "/ecs/${var.project_prefix}/app"
  retention_in_days = 7
}