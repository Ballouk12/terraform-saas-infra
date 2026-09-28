output "vpc_id" {
  description = "ID of the VPC. Consumed by security-groups, alb, ec2, rds, elasticache modules."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC. Used to scope security group ingress rules to internal traffic only."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, one per AZ. Consumed by the alb module."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, one per AZ. Consumed by the ec2/autoscaling (Kubernetes worker nodes) modules."
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the isolated database subnets, one per AZ."
  value       = aws_subnet.database[*].id
}

output "availability_zones" {
  description = "List of Availability Zones actually used, in the same order as the subnet lists above."
  value       = local.azs
}

output "db_subnet_group_name" {
  description = "Name of the DB Subnet Group, to be passed directly into the rds module's db_subnet_group_name argument."
  value       = aws_db_subnet_group.this.name
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache Subnet Group, to be passed directly into the elasticache module."
  value       = aws_elasticache_subnet_group.this.name
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateway(s) — one or many depending on single_nat_gateway."
  value       = aws_nat_gateway.this[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route table(s), one per AZ."
  value       = aws_route_table.private[*].id
}
