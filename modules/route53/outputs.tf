output "zone_id" {
  value = local.zone_id
}

output "name_servers" {
  description = "Only populated when create_zone = true. Point your domain registrar's NS records at these."
  value       = var.create_zone ? aws_route53_zone.this[0].name_servers : []
}

output "record_fqdn" {
  value = aws_route53_record.app.fqdn
}
