# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AWS infrastructure repository for **10xR Healthcare** platform services using Terraform. This is a **HIPAA-compliant** healthcare application architecture managing ECS Fargate deployments, VPC networking, load balancers, DocumentDB (MongoDB-compatible), Redis caching, and supporting infrastructure.

**Deployment Region**: US-only (us-east-1) using AWS Route 53 for DNS management.

---

## Terraform Cloud Configuration

This project uses **Terraform Cloud** for state management and remote execution.

| Setting | Value |
|---------|-------|
| Organization | `10XR` |
| Project | `10XR AWS Infra` |
| QA Workspace | `qa-us-east-1-ten-xr-app` |
| Prod Workspace | `prod-us-east-1-ten-xr-app` |

### Workspace Naming Convention
```
{environment}-us-east-1-ten-xr-app
```

### Terraform Cloud UI
- **URL**: https://app.terraform.io/app/10XR/workspaces
- Plans and applies can be triggered and monitored from the TFC UI
- Variables (including sensitive ones) are configured in workspace settings

---

## Common Commands

```bash
# Login to Terraform Cloud (required once)
terraform login

# Initialize Terraform for an environment (connects to TFC workspace)
cd environments/qa && terraform init
cd environments/prod && terraform init

# Plan changes (runs in Terraform Cloud)
terraform plan

# Apply changes (runs in Terraform Cloud)
terraform apply

# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state (from Terraform Cloud)
terraform show

# List resources in state
terraform state list
```

---

## Architecture Overview

### High-Level Architecture Diagram

```
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │                        INTERNET                              │
                                    └─────────────────────────────────────────────────────────────┘
                                                              │
                                                              ▼
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │                    AWS ROUTE 53                              │
                                    │           (DNS Management - US Region Only)                  │
                                    │                  Hosted Zone: 10xr.co                        │
                                    └─────────────────────────────────────────────────────────────┘
                                                              │
                              ┌───────────────────────────────┼───────────────────────────────┐
                              │                               │                               │
                              ▼                               ▼                               ▼
                    ┌─────────────────┐            ┌─────────────────┐            ┌─────────────────┐
                    │ *.qa.10xr.co    │            │ *.prod.10xr.co  │            │  app.10xr.co    │
                    │   (A Record)    │            │   (A Record)    │            │   (A Record)    │
                    └─────────────────┘            └─────────────────┘            └─────────────────┘
                              │                               │                               │
                              └───────────────────────────────┼───────────────────────────────┘
                                                              │
                                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                         AWS VPC (10.0.0.0/16) - us-east-1                                    │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                         PUBLIC SUBNETS                                                 │  │
│  │                              (10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24)                             │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                            NETWORK LOAD BALANCER (NLB)                                          │  │  │
│  │  │                         (Public-facing, TCP Passthrough)                                        │  │  │
│  │  │                    Ports: 80 (HTTP) → ALB, 443 (HTTPS) → ALB                                    │  │  │
│  │  │                         Route 53 Alias Record → NLB DNS                                         │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────────────┘  │  │
│  │                                              │                                                         │  │
│  │  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                                             │  │
│  │  │ NAT Gateway  │    │ NAT Gateway  │    │ NAT Gateway  │   (One per AZ for HA)                       │  │
│  │  │   AZ-1a      │    │   AZ-1b      │    │   AZ-1c      │                                             │  │
│  │  └──────────────┘    └──────────────┘    └──────────────┘                                             │  │
│  └───────────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                     │                                                        │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                        PRIVATE SUBNETS                                                 │  │
│  │                              (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)                                   │  │
│  │                                                                                                        │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                        APPLICATION LOAD BALANCER (ALB) - Internal                               │  │  │
│  │  │                              (Host-based routing, HTTPS termination)                            │  │  │
│  │  │                                   ACM Certificate (*.10xr.co)                                   │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐   │  │  │
│  │  │  │                              LISTENER RULES (Host Headers)                              │   │  │  │
│  │  │  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │   │  │  │
│  │  │  │  │agents.*.co  │ │proxy.*.co   │ │analytics.*  │ │api.*.co     │ │*.10xr.co    │       │   │  │  │
│  │  │  │  │  → voice    │ │  → livekit  │ │  → analytics│ │  → agentic  │ │  → ui-console│       │   │  │  │
│  │  │  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘       │   │  │  │
│  │  │  └─────────────────────────────────────────────────────────────────────────────────────────┘   │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────────────┘  │  │
│  │                                                     │                                                  │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                              ECS FARGATE CLUSTER                                                 │  │  │
│  │  │                        (Serverless containers, awsvpc networking)                               │  │  │
│  │  │                                                                                                  │  │  │
│  │  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │  │  │
│  │  │   │ voice-agent  │  │livekit-proxy │  │agent-analyt. │  │agentic-svc   │  │ ui-console   │      │  │  │
│  │  │   │  Port: 9600  │  │  Port: 9000  │  │  Port: 9800  │  │  Port: 8080  │  │  Port: 3000  │      │  │  │
│  │  │   │CPU:4096 M:8GB│  │CPU:1024 M:2GB│  │CPU:2048 M:4GB│  │CPU:1024 M:2GB│  │CPU:512 M:1GB │      │  │  │
│  │  │   └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘      │  │  │
│  │  │                                                                                                  │  │  │
│  │  │   ┌──────────────┐                                                                               │  │  │
│  │  │   │automation-mcp│   Service Discovery: {service}.{cluster}-{env}.local                         │  │  │
│  │  │   │  Port: 8090  │   Auto-scaling: CPU/Memory based (min:1, max:8-10)                           │  │  │
│  │  │   │CPU:1024 M:2GB│   Capacity: FARGATE + FARGATE_SPOT                                           │  │  │
│  │  │   └──────────────┘                                                                               │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────────────┘  │  │
│  │                                                     │                                                  │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                              ELASTICACHE REDIS (Optional)                                        │  │  │
│  │  │               (Replication Group, Multi-AZ, Auth Token, Encryption)                             │  │  │
│  │  │                     Transit Encryption: TLS | At-Rest Encryption: AES-256                       │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                       DATABASE SUBNETS                                                 │  │
│  │                              (10.0.201.0/24, 10.0.202.0/24, 10.0.203.0/24)                             │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                              AMAZON DOCUMENTDB                                                   │  │  │
│  │  │                   (MongoDB 5.0 Compatible, Multi-AZ, HIPAA Compliant)                           │  │  │
│  │  │                 Encryption: KMS (at-rest) | TLS 1.2+ (in-transit)                               │  │  │
│  │  │                 Audit Logs: CloudWatch | Credentials: Secrets Manager                           │  │  │
│  │  │                 Instance: db.r6g.large | Cluster Size: 2 (Primary + Replica)                    │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                       VPC ENDPOINTS                                                    │  │
│  │   S3 (Gateway) | ECR | ECS | SSM | Secrets Manager | CloudWatch Logs | KMS | STS                      │  │
│  │                         (Private connectivity - no internet traversal)                                 │  │
│  └───────────────────────────────────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                     │
                                                     ▼
                              ┌─────────────────────────────────────────────────────────────────┐
                              │                    EXTERNAL SERVICES                            │
                              │  ┌─────────────────┐  ┌─────────────────┐                     │
                              │  │    LiveKit      │  │   Third-party   │                     │
                              │  │   (Real-time)   │  │      APIs       │                     │
                              │  └─────────────────┘  └─────────────────┘                     │
                              └─────────────────────────────────────────────────────────────────┘
```

### DNS Architecture (Route 53)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AWS ROUTE 53                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Hosted Zone: 10xr.co                                                        │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         DNS RECORDS                                     │ │
│  ├────────────────────────────────────────────────────────────────────────┤ │
│  │                                                                         │ │
│  │  QA Environment:                                                        │ │
│  │  ├── qa.10xr.co          → Alias → NLB (QA)                            │ │
│  │  ├── *.qa.10xr.co        → Alias → NLB (QA)                            │ │
│  │  ├── api.qa.10xr.co      → Alias → NLB (QA)                            │ │
│  │  ├── agents.qa.10xr.co   → Alias → NLB (QA)                            │ │
│  │  ├── proxy.qa.10xr.co    → Alias → NLB (QA)                            │ │
│  │  └── analytics.qa.10xr.co → Alias → NLB (QA)                           │ │
│  │                                                                         │ │
│  │  Production Environment:                                                │ │
│  │  ├── app.10xr.co         → Alias → NLB (Prod)                          │ │
│  │  ├── *.prod.10xr.co      → Alias → NLB (Prod)                          │ │
│  │  ├── api.prod.10xr.co    → Alias → NLB (Prod)                          │ │
│  │  ├── agents.prod.10xr.co → Alias → NLB (Prod)                          │ │
│  │  ├── proxy.prod.10xr.co  → Alias → NLB (Prod)                          │ │
│  │  └── analytics.prod.10xr.co → Alias → NLB (Prod)                       │ │
│  │                                                                         │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  Features:                                                                   │
│  • Alias records (no additional lookup latency)                             │
│  • Health checks integrated with NLB                                         │
│  • Automatic failover support                                                │
│  • DNSSEC available for domain security                                      │
│  • Native AWS integration with ACM for SSL validation                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## HIPAA Compliance Features

This infrastructure implements AWS HIPAA-eligible services and security best practices:

### Data Protection
| Feature | Implementation |
|---------|----------------|
| **Encryption at Rest** | DocumentDB KMS, Redis AES-256, S3 SSE, EBS encryption |
| **Encryption in Transit** | TLS 1.2+ (DocumentDB, ALB, NLB, Redis, VPC endpoints) |
| **Secrets Management** | AWS Secrets Manager & SSM Parameter Store (SecureString) |
| **Key Management** | AWS KMS for encryption keys (auto-rotation enabled) |
| **Database Audit Logs** | DocumentDB audit logs to CloudWatch |

### Network Security
| Feature | Implementation |
|---------|----------------|
| **Network Isolation** | Private subnets for all compute workloads |
| **VPC Endpoints** | Private AWS API access (no internet traversal) |
| **Security Groups** | Least-privilege, service-specific rules |
| **No Public IPs** | ECS tasks have no public IP addresses |
| **NAT Gateways** | One per AZ for HA outbound connectivity |
| **US-Only Deployment** | Single region (us-east-1) for data residency |

### Access Control
| Feature | Implementation |
|---------|----------------|
| **IAM Roles** | Per-service task roles with least privilege |
| **Task Execution Roles** | Separate roles for ECS agent operations |
| **No Hardcoded Credentials** | All secrets via Secrets Manager/SSM |

### Audit & Monitoring
| Feature | Implementation |
|---------|----------------|
| **VPC Flow Logs** | Network traffic logging to CloudWatch |
| **CloudWatch Logs** | Centralized application logging |
| **ALB/NLB Access Logs** | Load balancer request logging to S3 |
| **Container Insights** | ECS performance monitoring |
| **Route 53 Query Logs** | DNS query logging (optional) |

### High Availability
| Feature | Implementation |
|---------|----------------|
| **Multi-AZ Deployment** | 3 AZs (us-east-1a, 1b, 1c) |
| **DocumentDB Multi-AZ** | Primary + replica instances with automatic failover |
| **Redis Multi-AZ** | Automatic failover enabled |
| **Auto-scaling** | CPU/Memory based scaling |
| **Health Checks** | Container + ALB + Route 53 health checks |

---

## Directory Structure

```
aws-infra/
├── environments/
│   ├── qa/                          # QA environment
│   │   ├── main.tf                  # Module orchestration
│   │   ├── variables.tf             # Input variables
│   │   ├── locals.tf                # Environment overrides, IAM policies
│   │   ├── outputs.tf               # Output values
│   │   ├── providers.tf             # AWS provider configuration
│   │   ├── versions.tf              # Terraform & provider versions
│   │   └── terraform.tfvars         # Variable values
│   └── prod/                        # Production environment
│       └── ...                      # Same structure as QA
│
└── modules/
    ├── vpc/                         # VPC & networking
    │   ├── main.tf                  # VPC, subnets, NAT, VPC endpoints
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── ecs/                         # ECS Fargate cluster
    │   ├── main.tf                  # Cluster, task definitions, services
    │   ├── alb.tf                   # Application Load Balancer
    │   ├── listeners.tf             # ALB listener rules (host routing)
    │   ├── security_groups.tf       # ECS & ALB security groups
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── networking/                  # NLB & public networking
    │   ├── main.tf                  # Network Load Balancer
    │   ├── s3.tf                    # Access/connection logs bucket
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── redis/                       # ElastiCache Redis (optional)
    │   ├── main.tf                  # Redis replication group
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── documentdb/                  # Amazon DocumentDB (MongoDB-compatible)
    │   ├── main.tf                  # DocumentDB cluster, instances, security
    │   ├── variables.tf             # Configuration options
    │   └── outputs.tf               # Connection info, secrets ARNs
    │
    ├── certs/                       # SSL/TLS certificates
    │   ├── main.tf                  # ACM certificate (DNS validation via Route 53)
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── route53/                     # DNS management (to be added)
        ├── main.tf                  # Route 53 hosted zone & records
        ├── variables.tf
        └── outputs.tf
```

---

## Module Dependencies

```
┌─────────┐
│  certs  │ ────────────────────────────────────────────────────┐
└────┬────┘                                                      │
     │ (ACM certificate with Route 53 DNS validation)            │
     ▼                                                           │
┌─────────┐                                                      │
│   vpc   │                                                      │
└────┬────┘                                                      │
     │                                                           │
     ├──────────────────────┬────────────────────┐               │
     │                      │                    │               │
     ▼                      ▼                    ▼               │
┌──────────┐         ┌───────────┐         ┌─────────┐          │
│documentdb│         │   redis   │         │   ecs   │◄─────────┘
│(database)│         │ (optional)│         │(compute)│
└────┬─────┘         └─────┬─────┘         └────┬────┘
     │                     │                    │
     └─────────────────────┴────────────────────┘
                           │
                           ▼
                     ┌───────────┐
                     │networking │
                     └─────┬─────┘
                           │
                           ▼
                     ┌───────────┐
                     │ route53   │  (DNS records pointing to NLB)
                     └───────────┘
```

---

## Services Configuration

Services are defined in `terraform.tfvars` under the `ecs_services` map:

| Service | Port | CPU | Memory | Domain Pattern |
|---------|------|-----|--------|----------------|
| `voice-agent` | 9600 | 4096 | 8192 | agents.{env}.10xr.co |
| `livekit-proxy` | 9000 | 1024 | 2048 | proxy.{env}.10xr.co |
| `agent-analytics` | 9800 | 2048 | 4096 | analytics.{env}.10xr.co |
| `agentic-services` | 8080 | 1024 | 2048 | api.{env}.10xr.co |
| `ui-console` | 3000 | 512 | 1024 | {env}.10xr.co, ui.{env}.10xr.co |
| `automation-service-mcp` | 8090 | 1024 | 2048 | automation.{env}.10xr.co |

### Service Configuration Structure

```hcl
ecs_services = {
  "service-name" = {
    image                    = "ECR_REPO_URI"
    image_tag               = "version"
    port                    = 8080
    cpu                     = 1024
    memory                  = 2048
    desired_count           = 2

    environment = {
      SERVICE_PORT = "8080"
      LOG_LEVEL    = "INFO"
    }

    secrets = []  # Merged with Redis/MongoDB in locals.tf

    capacity_provider_strategy = [
      { capacity_provider = "FARGATE", weight = 1, base = 1 },
      { capacity_provider = "FARGATE_SPOT", weight = 2, base = 0 }
    ]

    container_health_check = {
      command      = "curl -f http://localhost:8080/health || exit 1"
      interval     = 30
      timeout      = 20
      start_period = 90
      retries      = 3
    }

    health_check = {
      path                = "/health"
      interval            = 30
      timeout             = 20
      healthy_threshold   = 2
      unhealthy_threshold = 3
      matcher             = "200"
    }

    enable_auto_scaling        = true
    auto_scaling_min_capacity  = 1
    auto_scaling_max_capacity  = 8
    auto_scaling_cpu_target    = 70
    auto_scaling_memory_target = 80

    alb_host_headers         = ["api.qa.10xr.co"]
    enable_load_balancer     = true
    enable_service_discovery = true
  }
}
```

---

## Environment Differences

| Feature | QA | Production |
|---------|----|----|
| **Region** | us-east-1 | us-east-1 |
| **DNS** | Route 53 (*.qa.10xr.co) | Route 53 (*.prod.10xr.co, app.10xr.co) |
| **DocumentDB** | 2-node cluster (db.r6g.large) | 2+ node cluster (db.r6g.large) |
| **Redis** | Optional (can be disabled) | Full HA deployment |
| **Workspace** | `qa-us-east-1-ten-xr-app` | `prod-us-east-1-ten-xr-app` |

---

## Security Groups Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SECURITY GROUPS                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────┐       ┌──────────────────────┐                    │
│  │    NLB (Stateless)   │       │      ALB SG          │                    │
│  │   No security group  │ ───▶  │  Ingress: 80, 443    │                    │
│  │   (TCP passthrough)  │       │  from VPC CIDR       │                    │
│  └──────────────────────┘       └──────────┬───────────┘                    │
│                                             │                                │
│                                             ▼                                │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                        ECS SERVICE SECURITY GROUPS                    │   │
│  │                         (One per service)                             │   │
│  │                                                                       │   │
│  │  Ingress:                                                             │   │
│  │    - From ALB SG on service port                                      │   │
│  │    - From VPC CIDR (service-to-service)                              │   │
│  │    - Self (service discovery)                                         │   │
│  │                                                                       │   │
│  │  Egress:                                                              │   │
│  │    - All traffic to 0.0.0.0/0 (via NAT)                              │   │
│  │    - Port 6379 to Redis SG                                            │   │
│  │    - Port 27017 to DocumentDB SG                                      │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                             │                                │
│                                             ▼                                │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────┐   │
│  │      Redis SG        │  │   DocumentDB SG      │  │ VPC Endpoints SG │   │
│  │  Ingress: 6379       │  │  Ingress: 27017      │  │  Ingress: 443    │   │
│  │  from ECS SGs        │  │  from VPC CIDR       │  │  from VPC CIDR   │   │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Key Patterns & Conventions

### Naming Convention
```
{cluster_name}-{environment}-{component}
Example: ten-xr-healthcare-qa-alb
```

### Tagging Strategy
All resources are tagged with:
```hcl
tags = {
  Environment = "qa" | "prod"
  Project     = "10xR-Agents"
  Component   = "VPC" | "ECS" | "Redis" | "Networking"
  Platform    = "AWS"
  Terraform   = "true"
  ManagedBy   = "terraform"
}
```

### Secrets Injection (locals.tf)
Environment-specific `locals.tf` merges base service configs with:
- DocumentDB connection details (DOCUMENTDB_HOST, DOCUMENTDB_PORT, connection string from Secrets Manager)
- Redis connection details (REDIS_URL, REDIS_HOST, REDIS_PORT) - when enabled
- IAM policies for DocumentDB and ElastiCache access
- MongoDB-compatible environment variables for backward compatibility

---

## Important Notes

- **Terraform Version**: >= 1.7.0
- **AWS Provider**: >= 5.99.0
- **VPC Module**: `terraform-aws-modules/vpc/aws` v5.17
- **State Management**: Terraform Cloud (never local state)
- **SSL Policy**: `ELBSecurityPolicy-TLS-1-2-2017-01`
- **Container Networking**: awsvpc mode (each task gets ENI)
- **ECR Region**: us-east-1 (761018882607.dkr.ecr.us-east-1.amazonaws.com)
- **DNS Provider**: AWS Route 53 (US-only deployment)
- **Certificate Validation**: ACM with Route 53 DNS validation
- **DocumentDB Engine**: MongoDB 5.0 compatible (docdb5.0 parameter family)
- **DocumentDB TLS**: Required - applications must use TLS and include CA certificate

---

## Maintenance Notes

When updating this infrastructure:

1. **Adding a new service**: Add to `ecs_services` in `terraform.tfvars`, add listener rules in `modules/ecs/listeners.tf`
2. **Updating secrets**: Modify `locals.tf` in the environment directory
3. **Scaling changes**: Update `auto_scaling_*` parameters in service config
4. **New VPC endpoints**: Add to `endpoints` map in `modules/vpc/main.tf`
5. **Certificate changes**: Update SANs in environment's `main.tf` certs module call
6. **DNS changes**: Update Route 53 records in the route53 module or environment main.tf
7. **DocumentDB changes**: Update `documentdb_*` variables in `terraform.tfvars`
8. **DocumentDB scaling**: Modify `documentdb_cluster_size` or `documentdb_instance_class`

**Always run `terraform plan` before `terraform apply` and review changes carefully.**

---

## DocumentDB Configuration

### Connection Requirements

Applications connecting to DocumentDB must:
1. Use TLS (required for HIPAA compliance)
2. Download the AWS RDS CA certificate bundle (`global-bundle.pem`)
3. Use the connection string from Secrets Manager

### Connection String Format
```
mongodb://<username>:<password>@<endpoint>:27017/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false
```

### Environment Variables Injected to ECS Services
```
# Non-sensitive (environment variables)
DOCUMENTDB_HOST          = <cluster-endpoint>
DOCUMENTDB_READER_HOST   = <reader-endpoint>
DOCUMENTDB_PORT          = 27017
DOCUMENTDB_DATABASE      = ten_xr_agents_<env>
DOCUMENTDB_TLS_ENABLED   = true

# Sensitive (from Secrets Manager)
DOCUMENTDB_USERNAME           = <from-secrets-manager>
DOCUMENTDB_PASSWORD           = <from-secrets-manager>
DOCUMENTDB_CONNECTION_STRING  = <from-secrets-manager>

# MongoDB-compatible (for backward compatibility)
SPRING_DATA_MONGODB_URI  = <connection-string>
MONGO_DB_URL             = <connection-string>
MONGO_DB_URI             = <connection-string>
```

### DocumentDB Module Features
- **KMS Encryption**: Automatic key rotation enabled
- **Audit Logging**: All database operations logged to CloudWatch
- **Profiler**: Slow query logging (threshold: 100ms)
- **Secrets Manager**: Credentials stored with automatic rotation support
- **IAM Policy**: Auto-generated policy for ECS task access
- **CloudWatch Alarms**: CPU, memory, and connection monitoring