resource "aws_s3_bucket" "workspace_demo" {
  bucket = "acme-workspace-demo-${var.environment}"
  tags   = { Environment = var.environment }
}

resource "time_sleep" "demo_lock" {
  create_duration = "30s"
  depends_on      = [aws_s3_bucket.workspace_demo]
}
