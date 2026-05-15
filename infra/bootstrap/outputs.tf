output "state_bucket" {
  value       = aws_s3_bucket.tf_state.bucket
  description = "S3 bucket name — paste into workspace/backend.tf"
}

output "lock_table" {
  value       = aws_dynamodb_table.tf_lock.name
  description = "DynamoDB table name — paste into workspace/backend.tf"
}
