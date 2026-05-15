resource "aws_s3_bucket" "workspace_demo" {
  bucket = "acme-workspace-demo-${var.environment}"
  tags   = { Environment = var.environment }
}
