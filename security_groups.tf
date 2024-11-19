resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "allows http traffic inbound"
  vpc_id      = module.maximumpigs_fabric.vpc_id

  tags = local.tags
}

resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "allows http traffic inbound"
  vpc_id      = module.maximumpigs_fabric.vpc_id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.allow_http.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.allow_https.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  tags = local.tags
}

# resource "aws_security_group" "db_access" {
#   name        = "allow_db_access"
#   description = "allows db access from VPC subnets"
#   vpc_id      = module.maximumpigs_fabric.vpc_id

#   tags = local.tags
# }

# resource "aws_vpc_security_group_ingress_rule" "database" {
#   security_group_id = aws_security_group.db_access.id

#   cidr_ipv4   = module.maximumpigs_fabric.vpc_cidr_block
#   from_port   = 5432
#   to_port     = 5432
#   ip_protocol = "tcp"

#   tags = local.tags  
# }