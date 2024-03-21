variable "state_dynamodb_table_name" {
  type        = string
  description = "The name of the DynamoDB table for the Terraform state"
  default     = "falco-test-infra-state-lock"
}
