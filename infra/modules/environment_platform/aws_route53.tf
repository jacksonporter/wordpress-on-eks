resource "aws_route53_zone" "environment_region" {
  name = "${data.aws_region.current.name}.${var.environment}.${var.base_domain_zone_name}"
}

resource "aws_route53_record" "parent_ns_record" {
  zone_id = data.aws_route53_zone.base.id

  name = aws_route53_zone.environment_region.name
  type = "NS"
  ttl  = 500

  records = aws_route53_zone.environment_region.name_servers
}

resource "aws_route53_record" "environment_region_acm_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.environment_region.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.environment_region.zone_id

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
}

resource "aws_route53_record" "environment_region_ingress_nginx_lb" {
  zone_id = aws_route53_zone.environment_region.zone_id

  allow_overwrite = true
  name            = "lb.${aws_route53_zone.environment_region.name}"
  type            = "A"

  alias {
    name                   = data.aws_lb.ingress_nginx_alb_ingress.dns_name
    zone_id                = data.aws_lb.ingress_nginx_alb_ingress.zone_id
    evaluate_target_health = true
  }
}
