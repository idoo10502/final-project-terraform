# terraform {} (version, required_providers, empty backend "s3" {}) and provider "aws" with default_tags
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # stays empty: bucket / key / region / use_lockfile come from -backend-config
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "voting-app"
      Environment = var.env
      Owner       = var.name_prefix
    }
  }
}
