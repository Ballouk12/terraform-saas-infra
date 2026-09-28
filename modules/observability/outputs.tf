output "amp_workspace_id" {
  value = aws_prometheus_workspace.amp.id
}

output "grafana_endpoint" {
  value = aws_grafana_workspace.grafana.endpoint
}

output "grafana_workspace_id" {
  value = aws_grafana_workspace.grafana.id
}

output "grafana_api_key" {
  value     = aws_grafana_workspace_api_key.grafana.key
  sensitive = true
}

output "grafana_api_key_secret_arn" {
  value = aws_secretsmanager_secret.grafana_api_key.arn
}

