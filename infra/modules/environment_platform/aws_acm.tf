resource "aws_acm_certificate" "environment_region" {
  domain_name       = aws_route53_zone.environment_region.name
  validation_method = "DNS"
  subject_alternative_names = [
    "*.${aws_route53_zone.environment_region.name}"
  ]


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "environment_region" {
  certificate_arn         = aws_acm_certificate.environment_region.arn
  validation_record_fqdns = [for record in aws_route53_record.environment_region_acm_cert_validation : record.fqdn]
}
