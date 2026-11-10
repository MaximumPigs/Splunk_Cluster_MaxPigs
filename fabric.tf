# =============================================================================
# Maximumpigs_AWS_Fabric baseline lookups (read-only)
#
# Finds the VPC, subnets, zones, baseline security group and trusted IP prefix
# list by name and tag. Pinned to a release tag so module changes reach this
# repository only when the ref is bumped deliberately.
# =============================================================================

module "maximumpigs_fabric" {
  source = "git::https://github.com/MaximumPigs/TF_Modules_AWS.git//vpc?ref=v2.0.0"
}

locals {
  # Shorthand for the lookups used throughout this configuration.
  baseline_security_group_id = module.maximumpigs_fabric.baseline_security_group_id
  trusted_prefix_list_id     = module.maximumpigs_fabric.trusted_prefix_list_id

  # All nodes run in the ap-southeast-2a public subnet (no NAT gateway).
  node_subnet_id = module.maximumpigs_fabric.public_subnet_ids_by_az["ap-southeast-2a"]
}
