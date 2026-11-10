# =============================================================================
# Terraform and provider version constraints
#
# Matches Maximumpigs_AWS_Fabric so state and providers behave the same in
# every repository. Exact provider builds are pinned in .terraform.lock.hcl.
# =============================================================================

terraform {
  # 1.11+ for S3-native state locking (use_lockfile in backend.hcl).
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.72"
    }
  }

  # Partial configuration: terraform init -backend-config=backend.hcl
  backend "s3" {}
}
