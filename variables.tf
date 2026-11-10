# =============================================================================
# Input variables
# =============================================================================

variable "region" {
  description = "AWS region of the Maximumpigs_AWS_Fabric baseline."
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_account_id" {
  description = "AWS account ID this configuration may be applied to. When set, the provider refuses any other account."
  type        = string
  default     = null

  validation {
    condition     = var.aws_account_id == null || can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "key_pair" {
  description = "Optional EC2 key pair for SSH. Not needed for shell access: the Generic_EC2_Role profile includes Session Manager."
  type        = string
  default     = null
}
