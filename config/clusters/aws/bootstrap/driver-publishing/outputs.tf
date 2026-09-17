output "driver_publisher_role_arn" {
  description = "AWS role assumed by DriverKit publishing jobs."
  value       = aws_iam_role.driver_publisher.arn
}
