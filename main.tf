# =============================================================================
# Splunk cluster nodes
#
# Each role is an instance of the TF_Modules_AWS ec2 module (IMDSv2 required,
# A records in the Fabric zones). Nodes sit in the ap-southeast-2a public
# subnet behind the Fabric baseline security group: trusted IPs, intra-VPC
# traffic and outbound only. Configuration is applied by Ansible.
# =============================================================================

locals {
  project = "Splunk_Cluster"

  # Node counts per role. Changing a count adds or removes nodes.
  searchhead_count     = 0
  indexer_count        = 2
  heavyforwarder_count = 0
  manager_count        = 2

  searchheads     = toset([for i in range(local.searchhead_count) : format("splunksh%d", i)])
  indexers        = toset([for i in range(local.indexer_count) : format("splunkidx%d", i)])
  heavyforwarders = toset([for i in range(local.heavyforwarder_count) : format("splunkhf%d", i)])
  managers        = toset([for i in range(local.manager_count) : format("splunkmgr%d", i)])

  # Pinned image: a newer AMI must never replace running nodes implicitly.
  ami_id        = "ami-03f0544597f43a91d"
  instance_type = "t3.medium"

  # First-boot cloud-init for every node, keyed by hostname.
  user_data = {
    for node in setunion(local.searchheads, local.indexers, local.heavyforwarders, local.managers) :
    node => base64encode(templatefile("${path.module}/cloudinit/userdata.tmpl", {
      hostname = node
      domain   = module.maximumpigs_fabric.route53_private_name
    }))
  }
}

# -----------------------------------------------------------------------------
# Search heads (Splunk Web, also reachable through the load balancer)
# -----------------------------------------------------------------------------

module "searchhead" {
  source   = "git::https://github.com/MaximumPigs/TF_Modules_AWS.git//ec2?ref=v2.0.0"
  for_each = local.searchheads

  name          = each.value
  ami           = local.ami_id
  instance_type = local.instance_type

  root_block_device = [{
    volume_size = 20
  }]

  # Public IP for outbound internet (no NAT gateway); inbound is limited to
  # trusted IPs by the security groups.
  associate_public_ip_address = true
  subnet_id                   = local.node_subnet_id
  vpc_security_group_ids      = [local.baseline_security_group_id, aws_security_group.allow_http.id]

  key_name             = var.key_pair
  iam_instance_profile = "Generic_EC2_Role"

  dns_pub_zone_name  = module.maximumpigs_fabric.route53_public_name
  dns_priv_zone_name = module.maximumpigs_fabric.route53_private_name

  user_data_base64 = local.user_data[each.value]
}

# -----------------------------------------------------------------------------
# Indexers
# -----------------------------------------------------------------------------

module "indexer" {
  source   = "git::https://github.com/MaximumPigs/TF_Modules_AWS.git//ec2?ref=v2.0.0"
  for_each = local.indexers

  name          = each.value
  ami           = local.ami_id
  instance_type = local.instance_type

  root_block_device = [{
    volume_size = 20
  }]

  associate_public_ip_address = true
  subnet_id                   = local.node_subnet_id
  vpc_security_group_ids      = [local.baseline_security_group_id]

  key_name             = var.key_pair
  iam_instance_profile = "Generic_EC2_Role"

  dns_pub_zone_name  = module.maximumpigs_fabric.route53_public_name
  dns_priv_zone_name = module.maximumpigs_fabric.route53_private_name

  user_data_base64 = local.user_data[each.value]
}

# -----------------------------------------------------------------------------
# Heavy forwarders (receive forwarded data through the load balancer)
# -----------------------------------------------------------------------------

module "heavyforwarder" {
  source   = "git::https://github.com/MaximumPigs/TF_Modules_AWS.git//ec2?ref=v2.0.0"
  for_each = local.heavyforwarders

  name          = each.value
  ami           = local.ami_id
  instance_type = local.instance_type

  associate_public_ip_address = true
  subnet_id                   = local.node_subnet_id
  vpc_security_group_ids      = [local.baseline_security_group_id]

  key_name             = var.key_pair
  iam_instance_profile = "Generic_EC2_Role"

  dns_pub_zone_name  = module.maximumpigs_fabric.route53_public_name
  dns_priv_zone_name = module.maximumpigs_fabric.route53_private_name

  user_data_base64 = local.user_data[each.value]
}

# -----------------------------------------------------------------------------
# Managers (cluster manager, deployer, license manager)
# -----------------------------------------------------------------------------

module "manager" {
  source   = "git::https://github.com/MaximumPigs/TF_Modules_AWS.git//ec2?ref=v2.0.0"
  for_each = local.managers

  name          = each.value
  ami           = local.ami_id
  instance_type = local.instance_type

  root_block_device = [{
    volume_size = 20
  }]

  associate_public_ip_address = true
  subnet_id                   = local.node_subnet_id
  vpc_security_group_ids      = [local.baseline_security_group_id]

  key_name             = var.key_pair
  iam_instance_profile = "Generic_EC2_Role"

  dns_pub_zone_name  = module.maximumpigs_fabric.route53_public_name
  dns_priv_zone_name = module.maximumpigs_fabric.route53_private_name

  user_data_base64 = local.user_data[each.value]
}
