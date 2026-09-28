############################################
# Data sources
############################################

data "aws_availability_zones" "available" {
  state = "available"

  # Local zones / wavelength zones excluded — we only want standard AZs
  # so every subnet has consistent capability (NAT, ALB, RDS, etc.).
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zone_count)

  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "vpc"
    }
  )
}

############################################
# VPC
############################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support    = var.enable_dns_support

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

############################################
# Internet Gateway
############################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

############################################
# Public Subnets (ALB, NAT Gateways)
############################################

resource "aws_subnet" "public" {
  count = var.availability_zone_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.public_subnet_newbits, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "${local.name_prefix}-public-subnet-${count.index + 1}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

############################################
# Private Subnets (EC2 / Kubernetes worker nodes)
############################################

resource "aws_subnet" "private" {
  count = var.availability_zone_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.private_subnet_newbits, count.index + var.availability_zone_count)
  availability_zone = local.azs[count.index]

  tags = merge(local.common_tags, {
    Name                              = "${local.name_prefix}-private-subnet-${count.index + 1}"
    Tier                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

############################################
# Database Subnets (RDS / ElastiCache — isolated tier)
############################################

resource "aws_subnet" "database" {
  count = var.availability_zone_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.database_subnet_newbits, 200 + count.index)
  availability_zone = local.azs[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-subnet-${count.index + 1}"
    Tier = "database"
  })
}

############################################
# Elastic IPs for NAT Gateway(s)
############################################

resource "aws_eip" "nat" {
  count = var.single_nat_gateway ? 1 : var.availability_zone_count

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

############################################
# NAT Gateway(s)
############################################

resource "aws_nat_gateway" "this" {
  count = var.single_nat_gateway ? 1 : var.availability_zone_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-gw-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

############################################
# Route Table - Public
############################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = var.availability_zone_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

############################################
# Route Table(s) - Private
# One route table per AZ so each private subnet can route
# to its own AZ's NAT Gateway when single_nat_gateway = false,
# avoiding cross-AZ data transfer charges and the AZ-outage
# blast radius of a shared route table.
############################################

resource "aws_route_table" "private" {
  count = var.availability_zone_count

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt-${count.index + 1}"
  })
}

resource "aws_route" "private_nat_access" {
  count = var.availability_zone_count

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id          = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  count = var.availability_zone_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

############################################
# Route Table - Database (no internet route at all)
# Database subnets are fully isolated: no NAT route, no IGW route.
# Only reachable from within the VPC. This is the network-layer
# enforcement of "private database" from the business requirements.
############################################

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-rt"
  })
}

resource "aws_route_table_association" "database" {
  count = var.availability_zone_count

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

############################################
# DB Subnet Group (consumed later by the rds module)
############################################

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}

############################################
# ElastiCache Subnet Group (consumed later by the elasticache module)
############################################

resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name_prefix}-cache-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cache-subnet-group"
  })
}

############################################
# VPC Flow Logs (Security / Observability)
############################################

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc-flow-logs/${local.name_prefix}"
  retention_in_days = var.flow_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-flow-logs"
  })
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${local.name_prefix}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}



# Least-privilege inline policy: this role can ONLY write logs to the
# specific log group created above — nothing broader.
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${local.name_prefix}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  max_aggregation_interval = 60

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-flow-log"
  })
}
