terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.8"
}

provider "aws" {
  region = var.region
}

# TODO: implement in this order during the demo:
#   1. aws_s3_bucket            (lifecycle { prevent_destroy = true })
#   2. aws_s3_bucket_versioning
#   3. aws_dynamodb_table       (LockID hash key, lifecycle { prevent_destroy = true })
