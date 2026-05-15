output "state_bucket" {
  value       = aws_s3_bucket.state.bucket
  description = "S3 bucket name — paste into workspace/backend.tf"
}

output "lock_table" {
  value       = aws_dynamodb_table.locks.name
  description = "DynamoDB table name — paste into workspace/backend.tf"
}
