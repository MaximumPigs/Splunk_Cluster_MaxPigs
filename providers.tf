terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
  backend "s3" {
  }
}

provider "aws" {
  region = "ap-southeast-2"
}