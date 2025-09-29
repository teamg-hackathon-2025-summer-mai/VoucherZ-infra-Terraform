resource "aws_acm_certificate" "voucherz_alb" {
  domain_name = "voucherz.site"
  validation_method = "DNS"

  tags = {
    Name = "${var.project_prefix}-acm"
  }

  lifecycle {
    create_before_destroy = true
  }
}
