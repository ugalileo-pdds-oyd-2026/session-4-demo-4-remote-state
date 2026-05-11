variable "team_name" {
  type        = string
  description = "Name of the team"
}
variable "environment" {
  type        = string
  default     = "shared"
  description = "Environment name"
}
variable "region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region"
}
