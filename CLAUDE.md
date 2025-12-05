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
│  │  │  │           ┌───────────────────────┐       ┌───────────────────────┐                    │   │  │  │
│  │  │  │           │ homehealth.qa.10xr.co │       │  hospice.qa.10xr.co   │                    │   │  │  │
│  │  │  │           │    → home-health      │       │     → hospice         │                    │   │  │  │
│  │  │  │           └───────────────────────┘       └───────────────────────┘                    │   │  │  │
│  │  │  └─────────────────────────────────────────────────────────────────────────────────────────┘   │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────────────┘  │  │
│  │                                                     │                                                  │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                              ECS FARGATE CLUSTER                                                 │  │  │
│  │  │                        (Serverless containers, awsvpc networking)                               │  │  │
│  │  │                                                                                                  │  │  │
│  │  │   ┌────────────────────────────────┐    ┌────────────────────────────────┐                      │  │  │
│  │  │   │        home-health             │    │          hospice               │                      │  │  │
│  │  │   │     (Next.js Application)      │    │     (Next.js Application)      │                      │  │  │
│  │  │   │        Port: 3000              │    │        Port: 3000              │                      │  │  │
│  │  │   │    CPU: 1024  Memory: 2GB      │    │    CPU: 1024  Memory: 2GB      │                      │  │  │
│  │  │   │    homehealth.qa.10xr.co       │    │    hospice.qa.10xr.co          │                      │  │  │
│  │  │   └────────────────────────────────┘    └────────────────────────────────┘                      │  │  │
│  │  │                                                                                                  │  │  │
│  │  │   Service Discovery: {service}.{cluster}-{env}.local                                            │  │  │
│  │  │   Auto-scaling: CPU/Memory based (min:2, max:6)                                                 │  │  │
│  │  │   Capacity: FARGATE (base) + FARGATE_SPOT (burst)                                               │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────────────┘  │  │
│  │                                                     │                                                  │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                         S3 BUCKET (HIPAA-Compliant Patient Data)                                │  │  │
│  │  │               KMS Encryption | Versioning | Access Logging | 6-Year Retention                   │  │  │
│  │  │                     Bucket: ten-xr-app-{env}-patients                                           │  │  │
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
│  │                                  VPC ENDPOINTS (Cost-Optimized)                                        │  │
│  │   S3 (Gateway/FREE) | ECR (api+dkr) | ECS (ecs+agent) | STS | KMS | Logs | Secrets Manager            │  │
│  │                   (Private connectivity - no internet traversal, ~$176/mo)                             │  │
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

This infrastructure implements AWS HIPAA-eligible services and security best practices.

### Log Retention Requirements (6 Years / 2192 Days)

HIPAA requires audit log retention for **6 years (2192 days)**. The following components are configured:

| Component | Location | Retention | Configuration |
|-----------|----------|-----------|---------------|
| **ECS CloudWatch Logs** | CloudWatch Log Groups | 2192 days | `modules/ecs/variables.tf` → `log_retention_days` |
| **DocumentDB Audit Logs** | CloudWatch Log Groups | 2192 days | `modules/documentdb/variables.tf` → `cloudwatch_log_retention_days` |
| **Redis CloudWatch Logs** | CloudWatch Log Groups | 2192 days | `modules/redis/variables.tf` → `cloudwatch_log_retention_days` |
| **VPC Flow Logs** | CloudWatch Log Groups | 2192 days | `modules/vpc/variables.tf` → `flow_log_cloudwatch_log_retention_days` |
| **NLB Access Logs** | S3 Bucket | 2192 days | `modules/networking/s3.tf` → Lifecycle policy |
| **NLB Connection Logs** | S3 Bucket | 2192 days | `modules/networking/s3.tf` → Lifecycle policy |
| **ALB Access Logs** | S3 Bucket | 2192 days | Environment-level S3 bucket |

### S3 Log Lifecycle (Cost Optimization)

S3 buckets for logs use tiered storage to reduce long-term costs:

```
Day 1-90     → STANDARD (frequent access)
Day 91-365   → STANDARD_IA (infrequent access, ~40% savings)
Day 366-2192 → GLACIER (archive, ~80% savings)
Day 2191+    → Deleted (after 6-year retention)
```

### Access Logging (Enabled by Default)

| Resource | Logging Enabled | Configuration |
|----------|-----------------|---------------|
| **ALB Access Logs** | ✅ Yes (default: true) | `modules/ecs/variables.tf` → `alb_access_logs_enabled` |
| **ALB Connection Logs** | ✅ Yes (default: true) | `modules/ecs/variables.tf` → `alb_connection_logs_enabled` |
| **NLB Access Logs** | ✅ Yes (default: true) | `modules/networking/variables.tf` → `nlb_access_logs_enabled` |
| **NLB Connection Logs** | ✅ Yes (default: true) | `modules/networking/variables.tf` → `nlb_connection_logs_enabled` |

### Deletion Protection

| Resource | Protection Enabled | Configuration |
|----------|-------------------|---------------|
| **ALB** | ✅ Yes (default: true) | `modules/ecs/variables.tf` → `alb_enable_deletion_protection` |
| **NLB** | ✅ Yes (default: true) | `modules/networking/variables.tf` → `nlb_enable_deletion_protection` |
| **DocumentDB** | ✅ Yes (default: true) | `modules/documentdb/variables.tf` → `deletion_protection` |
| **S3 Log Buckets** | ✅ Yes (force_destroy: false) | `modules/networking/s3.tf` → Prevents accidental deletion |

### Data Protection
| Feature | Implementation |
|---------|----------------|
| **Encryption at Rest** | DocumentDB KMS, Redis AES-256, S3 SSE, EBS encryption |
| **Encryption in Transit** | TLS 1.2+ (DocumentDB, ALB, NLB, Redis, VPC endpoints) |
| **Secrets Management** | AWS Secrets Manager & SSM Parameter Store (SecureString) |
| **Key Management** | AWS KMS for encryption keys (auto-rotation enabled) |
| **Database Audit Logs** | DocumentDB audit logs to CloudWatch (2192-day retention) |

### Network Security
| Feature | Implementation |
|---------|----------------|
| **Network Isolation** | Private subnets for all compute workloads |
| **VPC Endpoints** | Private AWS API access (no internet traversal) |
| **Security Groups** | Least-privilege, service-specific rules |
| **No Public IPs** | ECS tasks have no public IP addresses |
| **NAT Gateways** | One per AZ for HA outbound connectivity |
| **US-Only Deployment** | Single region (us-east-1) for data residency |
| **VPC Flow Logs** | All traffic logged with 6-year retention |

### Access Control
| Feature | Implementation |
|---------|----------------|
| **IAM Roles** | Per-service task roles with least privilege |
| **Task Execution Roles** | Separate roles for ECS agent operations |
| **No Hardcoded Credentials** | All secrets via Secrets Manager/SSM |

### Audit & Monitoring
| Feature | Implementation |
|---------|----------------|
| **VPC Flow Logs** | Network traffic logging to CloudWatch (2192-day retention) |
| **CloudWatch Logs** | Centralized application logging (2192-day retention) |
| **ALB/NLB Access Logs** | Load balancer request logging to S3 (2192-day retention) |
| **Container Insights** | ECS performance monitoring |
| **Route 53 Query Logs** | DNS query logging (optional) |
| **DocumentDB Profiler** | Slow query logging (threshold: 100ms) |

### Backup & Recovery
| Feature | Implementation |
|---------|----------------|
| **DocumentDB Backups** | 60-day retention (daily automated backups) |
| **DocumentDB Window** | 03:00-05:00 UTC |
| **S3 Versioning** | Enabled on all log buckets |
| **Final Snapshots** | Required before cluster deletion |

### High Availability
| Feature | Implementation |
|---------|----------------|
| **Multi-AZ Deployment** | 3 AZs (us-east-1a, 1b, 1c) |
| **DocumentDB Multi-AZ** | Primary + replica instances with automatic failover |
| **Redis Multi-AZ** | Automatic failover enabled |
| **Auto-scaling** | CPU/Memory based scaling |
| **Health Checks** | Container + ALB + Route 53 health checks |

### CloudWatch Alarms (Enabled by Default)

| Resource | Alarms Enabled | Configuration |
|----------|----------------|---------------|
| **NLB Health** | ✅ Yes (default: true) | `modules/networking/variables.tf` → `create_cloudwatch_alarms` |
| **DocumentDB** | ✅ Yes (default: true) | `modules/documentdb/variables.tf` → `create_cloudwatch_alarms` |

### HIPAA Compliance Checklist

- [x] Encryption at rest (KMS, AES-256)
- [x] Encryption in transit (TLS 1.2+)
- [x] 6-year audit log retention (2192 days) - all log types
- [x] VPC Flow Logs enabled with 6-year retention
- [x] Database audit logging enabled (DocumentDB)
- [x] Load balancer access logging enabled by default (ALB + NLB)
- [x] Load balancer connection logging enabled by default
- [x] Deletion protection on critical resources (ALB, NLB, DocumentDB, S3)
- [x] S3 log buckets protected (force_destroy: false)
- [x] No public IPs on compute resources
- [x] Secrets in AWS Secrets Manager
- [x] IAM least-privilege access
- [x] Multi-AZ for high availability
- [x] Automated backups (60-day retention)
- [x] US-only data residency
- [x] CloudWatch alarms for critical metrics

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
    ├── s3-hipaa/                    # HIPAA-compliant S3 buckets for PHI
    │   ├── main.tf                  # S3 bucket, KMS encryption, policies
    │   ├── variables.tf             # Configuration options
    │   └── outputs.tf               # Bucket ARNs, IAM policy ARNs
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

| Service | Port | CPU | Memory | Domain Pattern | Description |
|---------|------|-----|--------|----------------|-------------|
| `home-health` | 3000 | 1024 | 2048 | homehealth.{env}.10xr.co | Home Health Next.js application |
| `hospice` | 3000 | 1024 | 2048 | hospice.{env}.10xr.co | Hospice Next.js application |

### ECR Repositories

| Service | ECR Repository |
|---------|---------------|
| Home Health | `761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/home-health` |
| Hospice | `761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/hospice` |

### Service Configuration Structure

```hcl
ecs_services = {
  "home-health" = {
    image         = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/home-health"
    image_tag     = "latest"
    port          = 3000
    cpu           = 1024
    memory        = 2048
    desired_count = 2

    environment = {
      PORT = "3000"
    }

    secrets = []  # Secrets injected via locals.tf from Secrets Manager

    capacity_provider_strategy = [
      { capacity_provider = "FARGATE", weight = 1, base = 1 },
      { capacity_provider = "FARGATE_SPOT", weight = 1, base = 0 }
    ]

    enable_auto_scaling        = true
    auto_scaling_min_capacity  = 2
    auto_scaling_max_capacity  = 6

    alb_host_headers         = ["homehealth.qa.10xr.co"]
    enable_load_balancer     = true
    enable_service_discovery = true
  }
}
```

### Environment Variables Injected (via locals.tf)

Each service automatically receives:

| Variable | Source | Description |
|----------|--------|-------------|
| `NEXT_PUBLIC_BASE_URL` | SSM | Service base URL (e.g., https://homehealth.qa.10xr.co) |
| `NEXTAUTH_URL` | SSM | NextAuth callback URL |
| `NODE_ENV` | Environment | `production` |
| `DOCUMENTDB_HOST` | DocumentDB Module | Primary cluster endpoint |
| `DOCUMENTDB_PORT` | DocumentDB Module | `27017` |
| `S3_BUCKET_NAME` | S3 Module | Patient data bucket name |
| `AWS_REGION` | Environment | `us-east-1` |

### Secrets Injected (via Secrets Manager)

| Secret | Source | Description |
|--------|--------|-------------|
| `MONGODB_URI` | DocumentDB Secret | Full connection string with credentials |
| `NEXTAUTH_SECRET` | Service Secret | NextAuth encryption key |
| `ONTUNE_SECRET` | Service Secret | OnTune integration secret |
| `ADMIN_API_KEY` | Service Secret | Admin API authentication key |
| `GEMINI_API_KEY` | Service Secret | Google Gemini API key |
| `OPENAI_API_KEY` | Service Secret | OpenAI API key (home-health only) |

### Terraform Cloud Variables (Sensitive)

Set these in Terraform Cloud workspace:

```
# Home Health Secrets
home_health_nextauth_secret  = "..."
home_health_ontune_secret    = "..."
home_health_admin_api_key    = "..."
home_health_gemini_api_key   = "..."
home_health_openai_api_key   = "..."

# Hospice Secrets
hospice_nextauth_secret      = "..."
hospice_ontune_secret        = "..."
hospice_admin_api_key        = "..."
hospice_gemini_api_key       = "..."
```

---

## S3 Patient Data Bucket

HIPAA-compliant S3 bucket for storing patient data (PHI):

| Feature | Configuration |
|---------|---------------|
| **Bucket Name** | `{cluster}-{env}-patients` |
| **Encryption** | KMS (customer-managed key with rotation) |
| **Versioning** | Enabled |
| **Access Logging** | Enabled |
| **Public Access** | Blocked |
| **SSL Required** | Yes (bucket policy enforces) |
| **Retention** | 6 years (2192 days) |
| **Lifecycle** | Standard → Standard-IA (90d) → Glacier (365d) |

Access is granted via IAM task roles - no AWS access keys needed.

---

## Environment Differences

| Feature | QA | Production |
|---------|----|----|
| **Region** | us-east-1 | us-east-1 |
| **DNS** | Route 53 (homehealth.qa.10xr.co, hospice.qa.10xr.co) | Route 53 (homehealth.10xr.co, hospice.10xr.co) |
| **DocumentDB** | 2-node cluster (db.r6g.large) | 2+ node cluster (db.r6g.large) |
| **S3 Bucket** | `ten-xr-app-qa-patients` | `ten-xr-app-prod-patients` |
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