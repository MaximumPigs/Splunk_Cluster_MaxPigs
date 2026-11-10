# =============================================================================
# Front-end load balancer (TLS) for Splunk Web and forwarder traffic
#
# TODO - Fix load balancer - make ALB
#
# Cost: an NLB is billed per hour whether or not it has targets, plus one
# public IPv4 address per subnet. With no search heads or heavy forwarders it
# carries no traffic.
# =============================================================================

resource "aws_lb" "front-end" {
  name               = "front-end"
  internal           = false
  load_balancer_type = "network"

  # Baseline group: clients must be trusted IPs; targets accept the
  # load balancer's traffic through the baseline intra-VPC rule.
  security_groups = [local.baseline_security_group_id]
  subnets         = module.maximumpigs_fabric.public_subnet_ids
}

# TLS 443 -> search heads (Splunk Web on 8000).
resource "aws_lb_listener" "searchhead" {
  load_balancer_arn = aws_lb.front-end.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.splunk.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.searchhead.arn
  }

}

# TLS 9997 -> heavy forwarders (forwarder data).
resource "aws_lb_listener" "heavyforwarder" {
  load_balancer_arn = aws_lb.front-end.arn
  port              = "9997"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.splunk.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.heavyforwarder.arn
  }

}

# Search head targets.
resource "aws_lb_target_group" "searchhead" {
  name     = "searchhead-lb-target-group"
  port     = 8000
  protocol = "TCP"
  vpc_id   = module.maximumpigs_fabric.vpc_id

}

# Heavy forwarder targets.
resource "aws_lb_target_group" "heavyforwarder" {
  name     = "heavyforwarder-lb-target-group"
  port     = 9997
  protocol = "TCP"
  vpc_id   = module.maximumpigs_fabric.vpc_id

}

# Register every search head instance.
resource "aws_lb_target_group_attachment" "searchhead" {
  for_each         = module.searchhead
  target_group_arn = aws_lb_target_group.searchhead.arn
  target_id        = each.value.id
  port             = 8000
}

# Register every heavy forwarder instance.
resource "aws_lb_target_group_attachment" "heavyforwarder" {
  for_each         = module.heavyforwarder
  target_group_arn = aws_lb_target_group.heavyforwarder.arn
  target_id        = each.value.id
  port             = 9997
}

# Public certificate for splunk.<public zone>, validated through DNS.
resource "aws_acm_certificate" "splunk" {
  domain_name       = "splunk.${module.maximumpigs_fabric.route53_public_name}"
  validation_method = "DNS"

  # A replacement certificate must exist before the listener lets go of the old one.
  lifecycle {
    create_before_destroy = true
  }

}

# splunk.<public zone> -> load balancer.
resource "aws_route53_record" "frontend" {
  zone_id = module.maximumpigs_fabric.route53_public_id
  name    = "splunk.${module.maximumpigs_fabric.route53_public_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.front-end.dns_name]
}

# DNS records ACM uses to validate the certificate.
resource "aws_route53_record" "frontend_validation" {
  for_each = {
    for dvo in aws_acm_certificate.splunk.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = module.maximumpigs_fabric.route53_public_id
}

# Waits until ACM has issued the certificate.
resource "aws_acm_certificate_validation" "splunk" {
  certificate_arn         = aws_acm_certificate.splunk.arn
  validation_record_fqdns = [for record in aws_route53_record.frontend_validation : record.fqdn]
}