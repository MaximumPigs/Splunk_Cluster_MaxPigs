# =============================================================================
# Workload security groups
#
# Inbound rules source the Fabric trusted-IP prefix list instead of the whole
# internet, so the IP allow-list is managed in one place (Maximumpigs_AWS_Fabric).
# =============================================================================

# HTTP to the search heads from trusted IPs.
resource "aws_security_group" "allow_http" {
  #checkov:skip=CKV2_AWS_5:Attached to the search heads through the ec2 module's vpc_security_group_ids, which checkov cannot follow.
  name        = "allow_http"
  description = "allows http traffic inbound"
  vpc_id      = module.maximumpigs_fabric.vpc_id

  lifecycle {
    # The lookups return null against a Fabric deployment that predates them.
    precondition {
      condition     = local.baseline_security_group_id != null && local.trusted_prefix_list_id != null
      error_message = "Fabric baseline security group or trusted prefix list not found. Apply Maximumpigs_AWS_Fabric (security uplift) first."
    }
  }
}

# HTTPS from trusted IPs (not attached to any instance yet).
resource "aws_security_group" "allow_https" {
  #checkov:skip=CKV2_AWS_5:Kept for search heads behind HTTPS; not attached while there are none.
  name        = "allow_https"
  description = "allows https traffic inbound"
  vpc_id      = module.maximumpigs_fabric.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  #checkov:skip=CKV_AWS_260:False positive: the source is the trusted prefix list (prefix_list_id), not 0.0.0.0/0; the check only reads prefix_list_ids.
  security_group_id = aws_security_group.allow_http.id
  description       = "HTTP from trusted IPs"

  # Null-prefix-list case is caught by the precondition on allow_http.
  prefix_list_id = local.trusted_prefix_list_id
  from_port      = 80
  to_port        = 80
  ip_protocol    = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.allow_https.id
  description       = "HTTPS from trusted IPs"

  prefix_list_id = local.trusted_prefix_list_id
  from_port      = 443
  to_port        = 443
  ip_protocol    = "tcp"

  lifecycle {
    precondition {
      condition     = local.trusted_prefix_list_id != null
      error_message = "Fabric trusted prefix list not found. Apply Maximumpigs_AWS_Fabric (security uplift) first."
    }
  }
}

# resource "aws_security_group" "db_access" {
#   name        = "allow_db_access"
#   description = "allows db access from VPC subnets"
#   vpc_id      = module.maximumpigs_fabric.vpc_id
# }

# resource "aws_vpc_security_group_ingress_rule" "database" {
#   security_group_id = aws_security_group.db_access.id

#   cidr_ipv4   = module.maximumpigs_fabric.vpc_cidr_block
#   from_port   = 5432
#   to_port     = 5432
#   ip_protocol = "tcp"
# }
