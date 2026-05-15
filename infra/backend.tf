terraform {
  backend "s3" {
    bucket         = "pdds-oyd-2026-session4-demo4-tfstate"
    key            = "workspace/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "pdds-oyd-2026-session4-demo4-terraform-locks"
    encrypt        = true
  }
}
