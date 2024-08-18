locals {
  project = "Splunk_Cluster"

  searchhead_count = 2
  indexer_count = 2
  heavyforwarder_count = 0
  manager_count = 1

  searchheads = toset([
    for i in range(local.searchhead_count) : format("splunksh%d", i)
  ])

  indexers = toset([
    for i in range(local.indexer_count) : format("splunkidx%d", i)
  ])

  heavyforwarders = toset([
    for i in range(local.heavyforwarder_count) : format("splunkhf%d", i)
  ])

  managers = toset([
    for i in range(local.manager_count) : format("splunkmgr%d", i)
  ])

  tags = {
    project   = local.project
    ManagedBy = "Terraform"
  }
}

module "searchhead" {
  for_each = local.searchheads

  source = "./.terraform/modules/maximumpigs_fabric/ec2"

  name = each.value

  ami           = "ami-03f0544597f43a91d"
  instance_type = "t3.medium"

  root_block_device = [{
    volume_size = 12
  }]

  tags = local.tags

  associate_public_ip_address = true

  key_name = var.key_pair

  subnet_id = module.maximumpigs_fabric.subnet_ap-southeast-2a_public_id

  dns_pub_zone_name  = module.maximumpigs_fabric.route53_public_name
  dns_priv_zone_name = module.maximumpigs_fabric.route53_private_name

  vpc_security_group_ids = [module.maximumpigs_fabric.default_security_group_id, aws_security_group.allow_http.id]

  user_data_base64 = base64encode(templatefile("cloudinit/userdata.tmpl", {
    hostname = "${each.value}",
    domain = "${module.maximumpigs_fabric.route53_private_name}"}))

  iam_instance_profile = "Generic_EC2_Role"
}

module "indexer" {
  for_each = local.indexers

  source = "./.terraform/modules/maximumpigs_fabric/ec2"

  name = each.value

  ami           = "ami-03f0544597f43a91d"
  instance_type = "t3.medium"

  root_block_device = [{
    volume_size = 15
  }]  

  tags = local.tags

  associate_public_ip_address = true

  key_name = var.key_pair

  subnet_id = module.maximumpigs_fabric.subnet_ap-southeast-2a_public_id

  dns_pub_zone_name  = module.maximumpigs_fabric.route53_public_name
  dns_priv_zone_name = module.maximumpigs_fabric.route53_private_name

  vpc_security_group_ids = [module.maximumpigs_fabric.default_security_group_id]

  user_data_base64 = base64encode(templatefile("cloudinit/userdata.tmpl", {
    hostname = "${each.value}",
    domain = "${module.maximumpigs_fabric.route53_private_name}"}))

  iam_instance_profile = "Generic_EC2_Role"
}

module "heavyforwarder" {
  for_each = local.heavyforwarders

  source = "./.terraform/modules/maximumpigs_fabric/ec2"

  name = each.value

  ami           = "ami-03f0544597f43a91d"
  instance_type = "t3.medium"

  tags = local.tags

  associate_public_ip_address = true

  key_name = var.key_pair

  subnet_id = module.maximumpigs_fabric.subnet_ap-southeast-2a_public_id

  dns_pub_zone_name  = module.maximumpigs_fabric.route53_public_name
  dns_priv_zone_name = module.maximumpigs_fabric.route53_private_name

  vpc_security_group_ids = [module.maximumpigs_fabric.default_security_group_id]

  user_data_base64 = base64encode(templatefile("cloudinit/userdata.tmpl", {
    hostname = "${each.value}",
    domain = "${module.maximumpigs_fabric.route53_private_name}"}))

  iam_instance_profile = "Generic_EC2_Role"
}

module "manager" {
  for_each = local.managers

  source = "./.terraform/modules/maximumpigs_fabric/ec2"

  name = each.value

  ami           = "ami-03f0544597f43a91d"
  instance_type = "t3.medium"

  root_block_device = [{
    volume_size = 12
  }]  

  tags = local.tags

  associate_public_ip_address = true

  key_name = var.key_pair

  subnet_id = module.maximumpigs_fabric.subnet_ap-southeast-2a_public_id

  dns_pub_zone_name  = module.maximumpigs_fabric.route53_public_name
  dns_priv_zone_name = module.maximumpigs_fabric.route53_private_name

  vpc_security_group_ids = [module.maximumpigs_fabric.default_security_group_id]

  user_data_base64 = base64encode(templatefile("cloudinit/userdata.tmpl", {
    hostname = "${each.value}",
    domain = "${module.maximumpigs_fabric.route53_private_name}"}))

  iam_instance_profile = "Generic_EC2_Role"
}