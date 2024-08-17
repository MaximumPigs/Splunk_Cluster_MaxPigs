resource "aws_lb" "front-end" {
  name               = "front-end"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [module.maximumpigs_fabric.default_security_group_id]
  subnets            = [module.maximumpigs_fabric.subnet_ap-southeast-2a_public_id, module.maximumpigs_fabric.subnet_ap-southeast-2b_public_id, module.maximumpigs_fabric.subnet_ap-southeast-2c_public_id]

  tags = local.tags
}

resource "aws_lb_listener" "searchhead" {
  load_balancer_arn = aws_lb.front-end.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.searchhead.arn
  }

  tags = local.tags
}

resource "aws_lb_listener" "heavyforwarder" {
  load_balancer_arn = aws_lb.front-end.arn
  port              = "9997"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.heavyforwarder.arn
  }

  tags = local.tags
}

resource "aws_lb_target_group" "searchhead" {
  name     = "searchhead-lb-target-group"
  port     = 8000
  protocol = "TCP"
  vpc_id   = module.maximumpigs_fabric.vpc_id

  tags = local.tags
}

resource "aws_lb_target_group" "heavyforwarder" {
  name     = "heavyforwarder-lb-target-group"
  port     = 9997
  protocol = "TCP"
  vpc_id   = module.maximumpigs_fabric.vpc_id

  tags = local.tags
}

resource "aws_lb_target_group_attachment" "searchhead" {
  for_each = module.searchhead
  target_group_arn = aws_lb_target_group.searchhead.arn
  target_id        = each.value.id
  port             = 8000
}

resource "aws_lb_target_group_attachment" "heavyforwarder" {
  for_each = module.heavyforwarder
  target_group_arn = aws_lb_target_group.heavyforwarder.arn
  target_id        = each.value.id
  port             = 9997
}

resource "aws_route53_record" "frontend" {
  zone_id = module.maximumpigs_fabric.route53_public_id
  name    = "splunk.${module.maximumpigs_fabric.route53_private_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.front-end.dns_name]
}