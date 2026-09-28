output "parameter_name" {
  value = aws_ssm_parameter.app_version.name
}

output "parameter_arn" {
  value = aws_ssm_parameter.app_version.arn
}
