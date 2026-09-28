locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "elasticache"
  })
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${local.name_prefix}-redis"
  description           = "Redis cache/session store for ${local.name_prefix}"

  engine         = "redis"
  engine_version = var.engine_version
  node_type      = var.node_type

  num_cache_clusters = var.num_cache_clusters

  subnet_group_name  = var.subnet_group_name
  security_group_ids = var.security_group_ids

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.automatic_failover_enabled

  # Encryption at rest and in transit — Redis often ends up holding session
  # tokens and cached user data, so both are enabled by default rather than
  # opt-in, consistent with the "Encrypted storage" business requirement.
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled

  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = "05:00-06:00"
  maintenance_window       = "sun:06:30-sun:07:30"

  auto_minor_version_upgrade = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-redis" })
}
