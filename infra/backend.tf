terraform {
  backend "s3" {
    region         = "us-west-2"
    bucket         = "pdds-oyd-2026-session4-demo4-tfstate"
    dynamodb_table = "pdds-oyd-2026-session4-demo4-terraform-locks"
    key            = "workspace/terraform.tfstate"
    encrypt        = true
  }
}
