############################################
# General
############################################

variable "project_name" {
  description = "Short project/company identifier used as a prefix for all resource names (e.g. binaitech)."
  type        = string
  default     = "binaitech"
}

variable "environment" {
  description = "Deployment environment: dev, staging, or prod. Used in naming and to gate environment-specific behavior (e.g. NAT HA)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Common tags applied to every resource in this module (cost allocation, ownership, compliance)."
  type        = map(string)
  default     = {}
}

############################################
# Networking - CIDR design
############################################

variable "vpc_cidr" {
  description = "Primary IPv4 CIDR block for the VPC. Sized to comfortably fit growth to 100k users across 3 AZs with room for future subnets (EKS pods, additional tiers)."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zone_count" {
  description = "Number of Availability Zones to spread subnets across. 3 is the AWS-recommended minimum for true no-single-point-of-failure HA. Must not exceed the number of AZs available in the selected region."
  type        = number
  default     = 3

  validation {
    condition     = var.availability_zone_count >= 2 && var.availability_zone_count <= 6
    error_message = "availability_zone_count must be between 2 and 6."
  }
}

variable "public_subnet_newbits" {
  description = "Number of additional bits used to carve public subnets out of vpc_cidr via cidrsubnet(). With a /16 VPC and newbits=8, each public subnet is a /24 (~251 usable IPs) — enough for NAT Gateways, the ALB, and any bastion/jump resources."
  type        = number
  default     = 8
}

variable "private_subnet_newbits" {
  description = "Number of additional bits used to carve private subnets out of vpc_cidr. Private subnets host EC2/Kubernetes worker nodes and must be sized much larger than public subnets since application and pod IPs live here. newbits=4 on a /16 gives /20 subnets (~4,091 usable IPs each) — needed for EKS/Kubernetes CNI IP consumption at 100k-user scale."
  type        = number
  default     = 4
}

variable "database_subnet_newbits" {
  description = "Number of additional bits used to carve dedicated database subnets out of vpc_cidr. Kept separate from the general private subnets so RDS and ElastiCache sit in their own isolated network tier with tighter security group / NACL scope. newbits=8 gives /24 subnets, plenty for DB/cache ENIs."
  type        = number
  default     = 8
}

############################################
# NAT Gateway strategy (cost vs HA trade-off)
############################################

variable "single_nat_gateway" {
  description = "If true, deploy exactly ONE NAT Gateway shared by all private subnets (cheaper, ~$32/mo + data processing, but the AZ hosting it becomes a partial single point of failure for outbound internet). If false, deploy one NAT Gateway per AZ (true HA, no cross-AZ NAT traffic charges, but multiplies NAT cost by availability_zone_count). Recommended: true for dev/staging, false for prod."
  type        = bool
  default     = true
}

############################################
# DNS
############################################

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC. Required for RDS endpoints, ALB DNS names, and EKS to resolve correctly."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS resolution in the VPC via the Amazon-provided DNS server."
  type        = bool
  default     = true
}

############################################
# Flow Logs (Security / Observability)
############################################

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch Logs for network traffic auditing, security incident investigation, and anomaly detection. Recommended true for staging/prod."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention period, in days, for VPC Flow Logs in CloudWatch Logs. Balances audit/compliance needs against CloudWatch storage cost."
  type        = number
  default     = 30
}
