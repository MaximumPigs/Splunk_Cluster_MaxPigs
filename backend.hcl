# Remote state: terraform init -backend-config=backend.hcl
region = "ap-southeast-2"
bucket = "terraform-backend-maximumpigs"
key    = "state/splunk_cluster_maxpigs/infra.tfstate"

# Server-side encryption of the state object.
encrypt = true

# S3-native state locking (Terraform 1.11+): stops two applies running at once.
use_lockfile = true
