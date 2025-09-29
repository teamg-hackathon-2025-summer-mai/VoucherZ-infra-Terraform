resource "aws_lb" "public_web" {
  name = "${var.project_prefix}-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb.id]

  subnets = [
    for s in aws_subnet.public : s.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_prefix}-alb"
  }
}

resource "aws_lb_target_group" "web_80" {
  name = "${var.project_prefix}-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"

  health_check {
    interval = 30
    path = "/healthz"
    protocol = "HTTP"
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 3
  }

  stickiness {
    type = "lb_cookie"
    enabled = true
    cookie_duration = 86400
  }

  tags = {
    Name = "${var.project_prefix}-target-group"
  }
}

resource "aws_lb_listener" "https_443" {
  load_balancer_arn = aws_lb.public_web.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate_validation.voucherz_alb.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web_80.arn
  }
}

resource "aws_lb_listener" "http_80_redirect" {
  load_balancer_arn = aws_lb.public_web.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port = 443
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}