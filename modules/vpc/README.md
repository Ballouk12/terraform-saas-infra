# VPC Module — `binaitech-vpc`

## 1. Folder tree

```
terraform/modules/vpc/
├── main.tf         # VPC, subnets, IGW, NAT, route tables, flow logs
├── variables.tf    # Inputs
├── outputs.tf      # Values exported to other modules
├── versions.tf     # Terraform + AWS provider constraints
└── README.md
```

This module is a **foundation module** — every other module (security-groups, alb, ec2, autoscaling, rds, elasticache) consumes its outputs (`vpc_id`, subnet IDs, subnet group names). It has no dependencies of its own.

---

## 2. What gets created

| Resource | Count | Purpose |
|---|---|---|
| `aws_vpc` | 1 | Isolated network boundary for the whole platform |
| `aws_internet_gateway` | 1 | Internet egress/ingress for public subnets only |
| `aws_subnet` (public) | 1 per AZ (default 3) | ALB + NAT Gateways |
| `aws_subnet` (private) | 1 per AZ | Kubernetes worker nodes / EC2 |
| `aws_subnet` (database) | 1 per AZ | RDS MySQL + ElastiCache Redis — fully isolated |
| `aws_eip` + `aws_nat_gateway` | 1 or 1-per-AZ | Outbound internet for private subnets |
| `aws_route_table` (public) | 1 | Routes 0.0.0.0/0 → IGW |
| `aws_route_table` (private) | 1 per AZ | Routes 0.0.0.0/0 → NAT (own-AZ NAT when HA mode) |
| `aws_route_table` (database) | 1 | **No internet route at all** |
| `aws_db_subnet_group` | 1 | Handed to the `rds` module |
| `aws_elasticache_subnet_group` | 1 | Handed to the `elasticache` module |
| `aws_flow_log` + CloudWatch Log Group + IAM role | 1 | Network audit trail |

---

## 3. Key design decisions

- **Three-tier subnets (public/private/database):** database subnets have no internet route at all — network-level enforcement of "private database," not just a security-group rule.
- **3 AZs by default:** satisfies the no-single-point-of-failure requirement and gives real headroom for the 1,000 → 100,000 user growth target.
- **CIDR sizing:** private subnets get `/20` (~4,091 IPs) because Kubernetes CNI burns one IP per pod — undersizing this is a common silent EKS outage cause at scale.
- **`single_nat_gateway` is a variable:** `true` for dev (~$32/mo, one shared NAT), `false` for prod (one NAT per AZ, true HA, no cross-AZ transfer fees).
- **Per-AZ private route tables:** so losing one AZ's NAT doesn't take down egress for the other AZs.
- **VPC Flow Logs with a least-privilege IAM role:** scoped to write only to its own CloudWatch Log Group ARN, not a wildcard.
- **Kubernetes subnet tags** (`kubernetes.io/role/elb` / `internal-elb`): lets a future EKS module auto-discover subnets instead of manual wiring.

## 4. Security considerations
Database subnets are unreachable from the internet even if a security group is misconfigured. Flow Logs capture accept+reject traffic for forensics. The Flow Logs role can only write to its own log group.

## 5. Cost considerations
The single biggest lever is the NAT Gateway strategy: ~$32/mo (dev, shared) vs ~$96/mo (prod, one per AZ) plus data processing — exposed as `single_nat_gateway` rather than hardcoded.

## 6. Dependency diagram

```
                         ┌─────────────────────┐
                         │   aws_vpc.this       │
                         └──────────┬───────────┘
                                    │
        ┌───────────────┬──────────┼───────────────┬───────────────┐
        ▼                ▼          ▼               ▼               ▼
 public subnets   private subnets  database subnets  IGW      flow_log (+IAM role,
  (per AZ)           (per AZ)         (per AZ)                 CW Log Group)
        │                │               │
        ▼                │               ▼
   EIP + NAT GW ◄─────────┘        db_subnet_group
   (per AZ or 1)                   elasticache_subnet_group
        │
        ▼
  private route table(s) ──► route 0.0.0.0/0 via NAT
  public route table      ──► route 0.0.0.0/0 via IGW
  database route table    ──► NO internet route

Outputs consumed downstream by:
  security-groups module ← vpc_id, vpc_cidr_block
  alb module              ← public_subnet_ids
  ec2 / autoscaling module ← private_subnet_ids
  rds module               ← db_subnet_group_name
  elasticache module       ← elasticache_subnet_group_name
```
