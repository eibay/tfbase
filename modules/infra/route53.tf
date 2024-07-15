

resource "aws_route53_record" "route-alb-record" {
  zone_id = var.infra_params.hosted_zone_id
  name    = var.infra_params.hosted_api_demo_name
  type    = "A"

  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}
