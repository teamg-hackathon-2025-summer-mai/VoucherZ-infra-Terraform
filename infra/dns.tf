resource "aws_route53_record" "apex_alb" {
  zone_id = data.aws_route53_zone.public.zone_id
  name = ""
  type = "A"

  alias {
    name = aws_lb.public_web.dns_name
    zone_id = aws_lb.public_web.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "voucherz_alb_validation" {
  for_each = {
    for dvo in aws_acm_certificate.voucherz_alb.domain_validation_options :
    dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }
  zone_id = data.aws_route53_zone.public.zone_id
  name = each.value.name
  type = each.value.type
  ttl = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "voucherz_alb" {
  certificate_arn         = aws_acm_certificate.voucherz_alb.arn
  validation_record_fqdns = [for r in aws_route53_record.voucherz_alb_validation : r.fqdn]
}