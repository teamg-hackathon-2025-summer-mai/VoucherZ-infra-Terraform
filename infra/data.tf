data "aws_route53_zone" "public" {
  name = "voucherz.site."
  private_zone = false
}