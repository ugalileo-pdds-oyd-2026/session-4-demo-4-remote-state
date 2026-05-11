terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
  required_version = ">= 1.8"
  # NOTE: no backend block yet — using local state
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "workspace_demo" {
  bucket = "acme-workspace-demo-${var.environment}"
  tags   = { Environment = var.environment }
}
