locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "route53"
  })
}

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0
  name  = var.domain_name

  tags = local.common_tags
}

data "aws_route53_zone" "existing" {
  count        = var.create_zone ? 0 : 1
  name         = var.domain_name
  private_zone = false
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

# Alias record — no extra Route53 query charge and it automatically tracks
# the ALB's IPs if AWS rotates them, unlike a plain CNAME/A record with a
# manually pasted IP.
resource "aws_route53_record" "app" {
  zone_id = local.zone_id
  name    = "${var.record_name}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
