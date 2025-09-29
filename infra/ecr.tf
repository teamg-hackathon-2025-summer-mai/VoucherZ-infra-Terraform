resource "aws_ecr_repository" "web" {
  name = "${var.project_prefix}-web"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_repository" "app" {
  name = "${var.project_prefix}-app"
  image_tag_mutability = "IMMUTABLE"
}