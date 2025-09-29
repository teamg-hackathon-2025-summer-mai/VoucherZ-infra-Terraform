resource "aws_security_group" "alb" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}-alb-sg"
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow inbound HTTP (80/tcp) from anywhere"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow inbound HTTPS (443/tcp) from anywhere"
}

resource "aws_security_group_rule" "alb_egress" {
  type = "egress"
  security_group_id = aws_security_group.alb.id
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic to anywhere"
}

resource "aws_security_group" "app_fargate" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}-app-sg"
    Role = "ecs-task"
  }
}

resource "aws_security_group_rule" "app_fargate_ingress" {
  type = "ingress"
  security_group_id = aws_security_group.app_fargate.id
  from_port = 8000
  to_port = 8000
  protocol = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description = "Allow inbound 8000/tcp only from ALB SG"
}

resource "aws_security_group_rule" "app_fargate_egress" {
  type = "egress"
  security_group_id = aws_security_group.app_fargate.id
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic to anywhere"
}

resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}-rds-sg"
  }
}

resource "aws_security_group_rule" "rds_ingress" {
  type = "ingress"
  security_group_id = aws_security_group.rds.id
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  source_security_group_id = aws_security_group.app_fargate.id
  description = "Allow inbound MySQL (3306/tcp) only from App Fargate SG"
}

resource "aws_security_group_rule" "rds_egress" {
  type = "egress"
  security_group_id = aws_security_group.rds.id
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic to anywhere"
}