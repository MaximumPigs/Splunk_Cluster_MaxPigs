# =============================================================================
# Unit tests: plan-only, mocked AWS provider and mocked Fabric lookups, so no
# credentials or network access to AWS are needed.
#   terraform init -backend=false && terraform test
# =============================================================================

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  # Zones looked up by the ec2 module for its A records.
  mock_data "aws_route53_zone" {
    defaults = {
      name    = "aws.maximumpigs.com"
      zone_id = "Z0123456789ABCDEFGHIJ"
    }
  }
}

# Stand-in for the Fabric baseline lookups (TF_Modules_AWS vpc module).
override_module {
  target = module.maximumpigs_fabric
  outputs = {
    vpc_id                     = "vpc-0123456789abcdef0"
    vpc_cidr_block             = "10.0.0.0/16"
    public_subnet_ids          = ["subnet-pub-a", "subnet-pub-b", "subnet-pub-c"]
    public_subnet_ids_by_az    = { "ap-southeast-2a" = "subnet-pub-a", "ap-southeast-2b" = "subnet-pub-b", "ap-southeast-2c" = "subnet-pub-c" }
    baseline_security_group_id = "sg-0baseline"
    trusted_prefix_list_id     = "pl-0trusted"
    route53_public_id          = "Z0PUBLIC"
    route53_public_name        = "aws.maximumpigs.com"
    route53_private_id         = "Z0PRIVATE"
    route53_private_name       = "aws.maximumpigs.com"
  }
}

# The real provider knows the validation record names at plan time; the mock
# does not, so supply them during plan (override_during needs Terraform 1.11+).
override_resource {
  target          = aws_acm_certificate.splunk
  override_during = plan
  values = {
    arn = "arn:aws:acm:ap-southeast-2:123456789012:certificate/test"
    domain_validation_options = [{
      domain_name           = "splunk.aws.maximumpigs.com"
      resource_record_name  = "_test.splunk.aws.maximumpigs.com."
      resource_record_type  = "CNAME"
      resource_record_value = "_test.acm-validations.aws."
    }]
  }
}

# The ec2 module has its own tests in TF_Modules_AWS. Stubbing it here keeps
# these tests on this repository's wiring, and avoids the module's
# root-volume check, which cannot be known before an instance exists.
override_module {
  target = module.indexer
  outputs = {
    id            = "i-0indexer"
    private_ip    = "10.0.101.10"
    dns_priv_fqdn = "splunkidx.aws.maximumpigs.com"
  }
}

override_module {
  target = module.manager
  outputs = {
    id            = "i-0manager"
    private_ip    = "10.0.101.20"
    dns_priv_fqdn = "splunkmgr.aws.maximumpigs.com"
  }
}

run "nodes_match_the_role_counts" {
  command = plan

  assert {
    condition     = keys(module.indexer) == ["splunkidx0", "splunkidx1"] && keys(module.manager) == ["splunkmgr0", "splunkmgr1"]
    error_message = "Expected two indexers and two managers."
  }

  assert {
    condition     = length(module.searchhead) == 0 && length(module.heavyforwarder) == 0
    error_message = "No search heads or heavy forwarders are configured."
  }

  assert {
    condition     = keys(local.user_data) == ["splunkidx0", "splunkidx1", "splunkmgr0", "splunkmgr1"]
    error_message = "Every node needs cloud-init user data."
  }
}

run "nodes_use_the_baseline_network" {
  command = plan

  assert {
    condition     = local.node_subnet_id == "subnet-pub-a" && local.baseline_security_group_id == "sg-0baseline"
    error_message = "Nodes must use the Fabric public subnet in 2a and the baseline security group."
  }
}

run "nothing_is_open_to_the_internet" {
  command = plan

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.http.prefix_list_id == "pl-0trusted" &&
      aws_vpc_security_group_ingress_rule.http.cidr_ipv4 == null &&
      aws_vpc_security_group_ingress_rule.https.prefix_list_id == "pl-0trusted" &&
      aws_vpc_security_group_ingress_rule.https.cidr_ipv4 == null
    )
    error_message = "Inbound rules must come from the trusted prefix list, not 0.0.0.0/0."
  }

  assert {
    condition     = aws_lb.front-end.security_groups == toset(["sg-0baseline"])
    error_message = "The load balancer must use the baseline security group."
  }

  assert {
    condition     = aws_lb.front-end.subnets == toset(["subnet-pub-a", "subnet-pub-b", "subnet-pub-c"])
    error_message = "The load balancer must span the three public subnets."
  }
}

run "missing_fabric_baseline_is_reported" {
  command = plan

  # A Fabric deployment without the baseline group and prefix list.
  override_module {
    target = module.maximumpigs_fabric
    outputs = {
      vpc_id                     = "vpc-0123456789abcdef0"
      vpc_cidr_block             = "10.0.0.0/16"
      public_subnet_ids          = ["subnet-pub-a", "subnet-pub-b", "subnet-pub-c"]
      public_subnet_ids_by_az    = { "ap-southeast-2a" = "subnet-pub-a" }
      baseline_security_group_id = null
      trusted_prefix_list_id     = null
      route53_public_id          = "Z0PUBLIC"
      route53_public_name        = "aws.maximumpigs.com"
      route53_private_id         = "Z0PRIVATE"
      route53_private_name       = "aws.maximumpigs.com"
    }
  }

  expect_failures = [
    aws_security_group.allow_http,
    aws_vpc_security_group_ingress_rule.https,
  ]
}
