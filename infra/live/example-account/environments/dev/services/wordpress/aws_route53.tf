resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "wordpress.${data.aws_route53_zone.this.name}"
  type    = "CNAME"
  ttl     = 300
  records = ["lb.${data.aws_route53_zone.this.name}"]
}
