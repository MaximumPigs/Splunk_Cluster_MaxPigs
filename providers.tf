# =============================================================================
# Provider configuration
# =============================================================================

provider "aws" {
  region = var.region

  # Refuse to run against any account other than the expected one.
  allowed_account_ids = var.aws_account_id == null ? null : [var.aws_account_id]

  # Applied to every taggable resource, including the EC2 instances.
  default_tags {
    tags = {
      Project    = local.project
      ManagedBy  = "terraform"
      Repository = "MaximumPigs/Splunk_Cluster_MaxPigs"
    }
  }
}
