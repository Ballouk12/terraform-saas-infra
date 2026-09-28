output "primary_endpoint_address" {
  description = "Write endpoint — app connects here for cache writes."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Read endpoint, load-balanced across replicas — use for read-heavy cache lookups."
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "port" {
  value = 6379
}
