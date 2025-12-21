# n8n Self-Hosting Infrastructure Guide for AWS

## Step-by-Step Implementation: Unified Scalable Architecture

This document provides a comprehensive, step-by-step guide for self-hosting n8n on AWS within the 10xR Healthcare platform using a **single, unified architecture** that scales from MVP to production without requiring architectural changes.

---

## Table of Contents

1. [Purpose & Assumptions](#1-purpose--assumptions)
2. [Architecture Decision: Phased vs Unified](#2-architecture-decision-phased-vs-unified)
3. [Unified Architecture Overview](#3-unified-architecture-overview)
4. [Implementation: Production-Ready from Day 1](#4-implementation-production-ready-from-day-1)
5. [Scaling the Unified Architecture](#5-scaling-the-unified-architecture)
6. [Security & Compliance Considerations](#6-security--compliance-considerations)
7. [Operational Playbooks](#7-operational-playbooks-conceptual)
8. [Decision Traceability](#8-decision-traceability)
9. [Final Checklists](#9-final-checklists)

---

## 1. Purpose & Assumptions

### 1.1 Role of n8n in the 10xR Platform

n8n serves as the workflow automation backbone for the 10xR Healthcare platform, enabling:

- **Integration orchestration**: Connecting home health and hospice applications with external services (LiveKit, third-party APIs, EHR systems)
- **Data pipeline automation**: Processing patient data, triggering notifications, and coordinating cross-service workflows
- **AI workflow execution**: Running AI-enhanced workflows for clinical decision support and documentation assistance
- **Event-driven automation**: Responding to system events, scheduled tasks, and user-triggered actions

### 1.2 Traffic & Usage Expectations (Scaling Tiers)

| Tier | Executions/Hour | Active Workflows | Concurrent Users | Use Case |
|------|-----------------|------------------|------------------|----------|
| **Starter** | 10-50 | 5-10 | 1-3 | Development, testing |
| **Growth** | 100-500 | 20-50 | 5-10 | Mixed dev/prod |
| **Production** | 1,000+ | 50-200+ | 10-50+ | Mission-critical |

### 1.3 Workflow Complexity Assumptions

- **Simple workflows**: HTTP requests, basic data transformation, notifications (60% of total)
- **Medium workflows**: Multi-step integrations, conditional logic, database operations (30% of total)
- **Complex workflows**: AI/ML integrations, large data processing, long-running operations (10% of total)

### 1.4 Alignment with Existing Infrastructure

This guide aligns with the existing 10xR AWS infrastructure patterns:

- **Compute**: ECS Fargate (consistent with home-health and hospice services)
- **Networking**: Existing VPC with public/private/database subnets
- **Load Balancing**: NLB → ALB architecture with host-based routing
- **Database**: PostgreSQL (RDS)
- **Region**: us-east-1 (US-only deployment for HIPAA compliance)
- **State Management**: Terraform Cloud

---

## 2. Architecture Decision: Phased vs Unified

### 2.1 The Problem with Phased Architecture

A traditional phased approach uses different architectures at each stage:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    PHASED APPROACH (NOT RECOMMENDED)                             │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│   PHASE 1 (MVP)              PHASE 2 (Growth)           PHASE 3 (Production)    │
│   ┌──────────────┐           ┌──────────────┐           ┌──────────────┐        │
│   │ Single n8n   │           │ Multi n8n    │           │ n8n Main     │        │
│   │ Instance     │    →      │ Instances    │     →     │ n8n Webhook  │        │
│   │ + SQLite/EFS │  MIGRATE  │ + RDS PG     │  MIGRATE  │ n8n Workers  │        │
│   └──────────────┘           └──────────────┘           │ + RDS + Redis│        │
│                                                         └──────────────┘        │
│   Cost: ~$20/mo              Cost: ~$200/mo             Cost: ~$1,000/mo        │
│                                                                                  │
│   ⚠️ MIGRATION 1:            ⚠️ MIGRATION 2:                                     │
│   - SQLite → PostgreSQL      - Add Redis                                        │
│   - Data export/import       - Enable queue mode                                │
│   - Downtime required        - Split into 3 services                            │
│   - Risk of data loss        - Reconfigure networking                           │
│   - Test all workflows       - Major Terraform changes                          │
│                              - Downtime required                                │
│                              - Risk of misconfiguration                         │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Cost of Architectural Transitions

| Transition | Direct Costs | Hidden Costs | Risk |
|------------|--------------|--------------|------|
| **MVP → Growth** | ~4-8 hours engineering | Downtime, testing, rollback prep | Data migration failure |
| **Growth → Production** | ~16-24 hours engineering | Extensive testing, new monitoring | Service misconfiguration |
| **Total Migration Cost** | **~$3,000-6,000** in engineering time | Potential production incidents | Cumulative risk |

**Hidden costs of migrations**:
- Re-testing all existing workflows after each migration
- Updating CI/CD pipelines
- Rewriting Terraform modules
- Updating monitoring and alerting
- Documentation updates
- Team retraining

### 2.3 The Unified Architecture Approach

**Recommendation**: Deploy production-ready architecture from Day 1, but with minimal scaling.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    UNIFIED APPROACH (RECOMMENDED)                                │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│   SAME ARCHITECTURE AT ALL STAGES - JUST SCALE UP                               │
│                                                                                  │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                                                                         │   │
│   │   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                │   │
│   │   │  n8n Main   │    │ n8n Webhook │    │ n8n Workers │                │   │
│   │   │  (UI/API)   │    │ (Receivers) │    │ (Executors) │                │   │
│   │   └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                │   │
│   │          │                  │                  │                        │   │
│   │          └──────────────────┼──────────────────┘                        │   │
│   │                             │                                           │   │
│   │                             ▼                                           │   │
│   │          ┌─────────────────────────────────────┐                        │   │
│   │          │         ElastiCache Redis           │                        │   │
│   │          │         (Queue Backend)             │                        │   │
│   │          └─────────────────────────────────────┘                        │   │
│   │                             │                                           │   │
│   │                             ▼                                           │   │
│   │          ┌─────────────────────────────────────┐                        │   │
│   │          │         RDS PostgreSQL              │                        │   │
│   │          │         (Persistent Store)          │                        │   │
│   │          └─────────────────────────────────────┘                        │   │
│   │                                                                         │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│   STARTER          →         GROWTH           →         PRODUCTION              │
│   Scale: Minimal             Scale: Medium               Scale: Full            │
│   Cost: ~$180/mo             Cost: ~$350/mo              Cost: ~$1,000/mo       │
│                                                                                  │
│   ✅ NO MIGRATIONS - Just adjust task counts and instance sizes                 │
│   ✅ NO DOWNTIME - Rolling updates only                                         │
│   ✅ NO RISK - Same architecture, same code, same config                        │
│   ✅ NO REWORK - Terraform changes are parameter updates only                   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 2.4 Cost Comparison: Phased vs Unified

| Period | Phased Approach | Unified Approach | Difference |
|--------|-----------------|------------------|------------|
| **Month 1-3 (MVP)** | $20/mo × 3 = $60 | $180/mo × 3 = $540 | +$480 |
| **Migration 1 Cost** | $3,000 (engineering) | $0 | -$3,000 |
| **Month 4-9 (Growth)** | $200/mo × 6 = $1,200 | $250/mo × 6 = $1,500 | +$300 |
| **Migration 2 Cost** | $4,000 (engineering) | $0 | -$4,000 |
| **Month 10-12 (Prod)** | $1,000/mo × 3 = $3,000 | $800/mo × 3 = $2,400 | -$600 |
| **TOTAL YEAR 1** | **$11,260** | **$4,440** | **-$6,820 (61% savings)** |

**Key Insight**: The unified approach costs more monthly at the start but saves significantly by avoiding migration engineering costs and risks.

### 2.5 Decision: Unified Architecture

**Selected Approach**: Production-ready unified architecture from Day 1

**Rationale**:
1. **No migration risk**: Zero data migrations, zero architectural changes
2. **Faster scaling**: Just update Terraform variables to scale
3. **Lower total cost**: Avoids expensive engineering time for migrations
4. **Operational simplicity**: One architecture to learn, monitor, and maintain
5. **Predictable costs**: Linear scaling, no surprise migration projects

**Trade-off Accepted**: Higher initial monthly cost (~$180 vs ~$20) in exchange for zero migration complexity

---

## 3. Unified Architecture Overview

### 3.1 Architecture Components

The unified architecture consists of five core components that remain constant across all scaling tiers:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         UNIFIED n8n ARCHITECTURE                                 │
│                    (Same at all scales - just adjust sizing)                     │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│                              INTERNET                                            │
│                                  │                                               │
│                                  ▼                                               │
│                         ┌─────────────────┐                                      │
│                         │   Route 53      │                                      │
│                         │ n8n.{env}.10xr.co                                      │
│                         └────────┬────────┘                                      │
│                                  │                                               │
│  ┌───────────────────────────────┼───────────────────────────────────────────┐  │
│  │                         PUBLIC SUBNETS                                     │  │
│  │                    ┌──────────┴──────────┐                                │  │
│  │                    │        NLB          │                                │  │
│  │                    └──────────┬──────────┘                                │  │
│  └───────────────────────────────┼───────────────────────────────────────────┘  │
│                                  │                                               │
│  ┌───────────────────────────────┼───────────────────────────────────────────┐  │
│  │                        PRIVATE SUBNETS                                     │  │
│  │                    ┌──────────┴──────────┐                                │  │
│  │                    │    ALB (Internal)   │                                │  │
│  │                    │  ┌───────┬───────┐  │                                │  │
│  │                    │  │n8n.* │webhook│  │  (Host-based routing)          │  │
│  │                    └──┴───┬───┴───┬───┴──┘                                │  │
│  │                           │       │                                        │  │
│  │           ┌───────────────┘       └───────────────┐                       │  │
│  │           ▼                                       ▼                        │  │
│  │  ┌─────────────────┐                    ┌─────────────────┐               │  │
│  │  │   n8n MAIN      │                    │  n8n WEBHOOK    │               │  │
│  │  │   (UI/API)      │                    │  (Receivers)    │               │  │
│  │  │                 │                    │                 │               │  │
│  │  │ Tasks: 1-2      │                    │ Tasks: 1-4      │               │  │
│  │  └────────┬────────┘                    └────────┬────────┘               │  │
│  │           │                                      │                         │  │
│  │           └──────────────────┬───────────────────┘                         │  │
│  │                              │                                             │  │
│  │                              ▼                                             │  │
│  │           ┌──────────────────────────────────────┐                         │  │
│  │           │         ElastiCache REDIS            │                         │  │
│  │           │         (Queue Backend)              │                         │  │
│  │           │                                      │                         │  │
│  │           │  Starter: cache.t3.micro (1 node)   │                         │  │
│  │           │  Growth:  cache.t3.small (1 node)   │                         │  │
│  │           │  Prod:    cache.r6g.large (cluster) │                         │  │
│  │           └──────────────────┬───────────────────┘                         │  │
│  │                              │                                             │  │
│  │                              ▼                                             │  │
│  │           ┌──────────────────────────────────────┐                         │  │
│  │           │          n8n WORKERS                 │                         │  │
│  │           │         (Executors)                  │                         │  │
│  │           │                                      │                         │  │
│  │           │  Tasks: 1-10 (auto-scaling)         │                         │  │
│  │           └──────────────────────────────────────┘                         │  │
│  └────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐  │
│  │                        DATABASE SUBNETS                                    │  │
│  │           ┌──────────────────────────────────────┐                         │  │
│  │           │         RDS PostgreSQL               │                         │  │
│  │           │                                      │                         │  │
│  │           │  Starter: db.t3.micro (single-AZ)   │                         │  │
│  │           │  Growth:  db.t3.small (single-AZ)   │                         │  │
│  │           │  Prod:    db.r6g.large (Multi-AZ)   │                         │  │
│  │           └──────────────────────────────────────┘                         │  │
│  └────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Component Responsibilities

| Component | Responsibility | Scaling Behavior |
|-----------|---------------|------------------|
| **n8n Main** | UI, API, workflow editor, scheduling | Fixed 1-2 tasks (HA only) |
| **n8n Webhook** | Receive external webhooks, enqueue to Redis | Scale with webhook traffic |
| **n8n Workers** | Execute workflows from queue | Scale with queue depth |
| **Redis** | Job queue, session store, pub/sub | Scale instance size |
| **PostgreSQL** | Workflow definitions, credentials, execution logs | Scale instance size |

### 3.3 Why Queue Mode from Day 1

Queue mode is essential for the unified architecture:

1. **Separation of concerns**: Each component can scale independently
2. **Reliability**: Failed executions can be retried from queue
3. **No duplicate executions**: Queue ensures exactly-once processing
4. **Graceful scaling**: Workers can be added/removed without disruption
5. **Observability**: Queue depth provides clear scaling signals

### 3.4 Networking Integration

n8n integrates into the existing VPC:

- **Public subnets**: NLB receives traffic from Route 53
- **Private subnets**: ALB routes to ECS services, Redis
- **Database subnets**: RDS PostgreSQL
- **VPC Endpoints**: ECR, Secrets Manager, S3, CloudWatch Logs

### 3.5 Load Balancing Strategy

| Component | Host Header | Target |
|-----------|-------------|--------|
| n8n Main | `n8n.{env}.10xr.co` | Main ECS service |
| n8n Webhooks | `webhook.n8n.{env}.10xr.co` | Webhook ECS service |

Both routes through: Route 53 → NLB → ALB (internal) → ECS

---

## 4. Implementation: Production-Ready from Day 1

### 4.1 Overview

This section provides step-by-step implementation of the unified architecture. All components are deployed from the start, but sized minimally for the Starter tier.

### 4.2 Step 1: AWS Account and Network Confirmation

**Action**: Confirm deployment within the existing 10xR AWS infrastructure

**Details**:
- AWS Account: 761018882607
- Region: us-east-1
- VPC: Existing 10xR VPC (10.0.0.0/16)
- Subnets: Use existing private and database subnets
- Terraform Cloud: Use existing workspace patterns

**Verification**: Confirm Terraform Cloud access and AWS credentials.

---

### 4.3 Step 2: Security Groups

**Action**: Create security groups for n8n components

**n8n Services Security Group** (`{cluster}-{env}-n8n-sg`):
- Ingress: Port 5678 from ALB security group
- Ingress: From VPC CIDR (service discovery)
- Egress: All to 0.0.0.0/0 (external integrations via NAT)

**n8n Workers Security Group** (`{cluster}-{env}-n8n-worker-sg`):
- Ingress: None (workers only pull from queue)
- Egress: All to 0.0.0.0/0

**Redis Security Group** (`{cluster}-{env}-n8n-redis-sg`):
- Ingress: Port 6379 from n8n services and worker SGs
- Egress: None

**RDS Security Group** (`{cluster}-{env}-n8n-rds-sg`):
- Ingress: Port 5432 from n8n services, webhooks, and workers SGs
- Egress: None

---

### 4.4 Step 3: RDS PostgreSQL Database

**Action**: Create RDS PostgreSQL instance

**Configuration (Starter Tier)**:

| Setting | Starter | Growth | Production |
|---------|---------|--------|------------|
| Instance Class | db.t3.micro | db.t3.small | db.r6g.large |
| Storage | 20 GB gp3 | 50 GB gp3 | 100 GB gp3 |
| Multi-AZ | No | No | Yes |
| Backup Retention | 7 days | 14 days | 35 days |
| Encryption | Yes (KMS) | Yes (KMS) | Yes (KMS) |
| Deletion Protection | No | Yes | Yes |

**Database Setup**:
- Database name: `n8n`
- Master username: `n8n_admin` (stored in Secrets Manager)
- Application user: `n8n_app` (created post-deploy)

**Why PostgreSQL from Day 1**:
- No SQLite-to-PostgreSQL migration later
- Proper connection pooling for multiple services
- Point-in-time recovery capability
- Required for queue mode

---

### 4.5 Step 4: ElastiCache Redis

**Action**: Create ElastiCache Redis for queue backend

**Configuration (Starter Tier)**:

| Setting | Starter | Growth | Production |
|---------|---------|--------|------------|
| Node Type | cache.t3.micro | cache.t3.small | cache.r6g.large |
| Cluster Mode | Disabled | Disabled | Enabled |
| Replicas | 0 | 0 | 1 per shard |
| Multi-AZ | No | No | Yes |
| Encryption in-transit | Yes | Yes | Yes |
| Encryption at-rest | Yes | Yes | Yes |
| Auth Token | Yes | Yes | Yes |

**Why Redis from Day 1**:
- Required for queue mode
- No "add Redis later" migration
- Session management for multi-instance
- Enables immediate horizontal scaling of workers

---

### 4.6 Step 5: EFS for Binary Storage (Optional)

**Action**: Create EFS for binary file storage

**Configuration**:
- Encryption: Yes (KMS)
- Performance mode: General Purpose
- Throughput mode: Bursting
- Mount targets: One per private subnet

**Use Case**:
- Store uploaded files
- Custom node modules
- Not for database (using RDS)

**Note**: For enterprise n8n, consider S3 for binary storage instead.

---

### 4.7 Step 6: Secrets Management

**Action**: Create secrets in AWS Secrets Manager

**Required Secrets**:

| Secret Name | Contents | Notes |
|-------------|----------|-------|
| `n8n/{env}/encryption-key` | N8N_ENCRYPTION_KEY | Critical - backup securely |
| `n8n/{env}/db-credentials` | DB username/password | Auto-rotation capable |
| `n8n/{env}/redis-auth` | Redis auth token | |
| `n8n/{env}/basic-auth` | UI username/password | |

**Critical**: The encryption key protects all stored credentials in n8n. Document secure backup procedure before deployment.

---

### 4.8 Step 7: ECR Repository

**Action**: Create ECR repository and mirror n8n image

**Repository**: `761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/n8n`

**Tagging Strategy**:
- `1.70.0` - Specific version
- `latest` - Current production version

**Image Update Process**:
1. Monitor n8n releases
2. Pull from Docker Hub: `n8nio/n8n:1.x.x`
3. Tag and push to ECR
4. Update Terraform variable
5. Deploy via Terraform apply

---

### 4.9 Step 8: ECS Task Definitions

**Action**: Create three ECS task definitions

**n8n Main Task Definition**:

| Setting | Starter | Growth | Production |
|---------|---------|--------|------------|
| CPU | 512 | 1024 | 1024 |
| Memory | 1024 MB | 2048 MB | 2048 MB |
| Desired Count | 1 | 1 | 2 |

**Environment Variables (Main)**:
```
EXECUTIONS_MODE=queue
N8N_DISABLE_PRODUCTION_MAIN_PROCESS=false
OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true
N8N_PROTOCOL=https
N8N_HOST=n8n.{env}.10xr.co
N8N_PORT=5678
QUEUE_BULL_REDIS_HOST=<redis-endpoint>
QUEUE_BULL_REDIS_PORT=6379
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=<rds-endpoint>
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
GENERIC_TIMEZONE=America/New_York
N8N_LOG_LEVEL=info
N8N_METRICS=true
```

**n8n Webhook Task Definition**:

| Setting | Starter | Growth | Production |
|---------|---------|--------|------------|
| CPU | 256 | 512 | 512 |
| Memory | 512 MB | 1024 MB | 1024 MB |
| Desired Count | 1 | 1 | 2 |
| Auto-scaling Max | 2 | 4 | 6 |

**Environment Variables (Webhook)**:
```
EXECUTIONS_MODE=queue
N8N_DISABLE_PRODUCTION_MAIN_PROCESS=true
N8N_RUNNERS_ENABLED=false
(+ same Redis and DB config as Main)
```

**n8n Worker Task Definition**:

| Setting | Starter | Growth | Production |
|---------|---------|--------|------------|
| CPU | 512 | 1024 | 1024 |
| Memory | 1024 MB | 2048 MB | 2048 MB |
| Desired Count | 1 | 2 | 2 |
| Auto-scaling Max | 2 | 4 | 10 |

**Environment Variables (Worker)**:
```
EXECUTIONS_MODE=queue
EXECUTIONS_PROCESS=worker
N8N_DISABLE_UI=true
N8N_CONCURRENCY=10
(+ same Redis and DB config as Main)
```

---

### 4.10 Step 9: ECS Services

**Action**: Create three ECS services

**n8n-main Service**:
- Task Definition: n8n-main
- Launch Type: FARGATE
- Platform Version: LATEST
- Desired Count: 1 (Starter)
- Capacity Providers: FARGATE only (stable, always-on)
- Load Balancer: Yes (ALB target group)
- Health Check Path: `/healthz`

**n8n-webhook Service**:
- Task Definition: n8n-webhook
- Launch Type: FARGATE
- Desired Count: 1 (Starter)
- Capacity Providers: FARGATE (50%), FARGATE_SPOT (50%)
- Load Balancer: Yes (ALB target group)
- Health Check Path: `/healthz`
- Auto-Scaling: Based on request count

**n8n-worker Service**:
- Task Definition: n8n-worker
- Launch Type: FARGATE
- Desired Count: 1 (Starter)
- Capacity Providers: FARGATE (30%), FARGATE_SPOT (70%)
- Load Balancer: No (pulls from Redis queue)
- Auto-Scaling: Based on queue depth

---

### 4.11 Step 10: ALB Configuration

**Action**: Configure ALB listener rules

**Listener Rules**:

| Priority | Host Header | Target Group | Notes |
|----------|-------------|--------------|-------|
| 10 | `webhook.n8n.{env}.10xr.co` | n8n-webhook-tg | Webhook traffic |
| 20 | `n8n.{env}.10xr.co` | n8n-main-tg | UI and API |

**Target Group Settings**:
- Protocol: HTTP
- Port: 5678
- Health Check: `/healthz`
- Stickiness: Enabled (1 hour) for main only

---

### 4.12 Step 11: Route 53 DNS

**Action**: Create DNS records

**Records**:
- `n8n.{env}.10xr.co` → Alias to NLB
- `webhook.n8n.{env}.10xr.co` → Alias to NLB

**Certificate**: Use existing wildcard `*.{env}.10xr.co`

---

### 4.13 Step 12: CloudWatch Configuration

**Action**: Configure logging and monitoring

**Log Groups** (2192 days retention for HIPAA):
- `/ecs/{cluster}/n8n-main`
- `/ecs/{cluster}/n8n-webhook`
- `/ecs/{cluster}/n8n-worker`

**Alarms**:

| Alarm | Threshold | Severity |
|-------|-----------|----------|
| Main task count < 1 | 1 minute | Critical |
| Worker task count < 1 | 5 minutes | Warning |
| Worker CPU > 80% | 5 minutes | Warning |
| Redis connections > 80% | 5 minutes | Warning |
| RDS CPU > 80% | 10 minutes | Warning |
| 5xx error rate > 5% | 5 minutes | Critical |

**Dashboard Widgets**:
- ECS task counts (all services)
- CPU/Memory utilization
- Redis queue depth (custom metric)
- ALB request count and latency
- RDS connections and CPU

---

### 4.14 Step 13: Auto-Scaling Configuration

**Action**: Configure auto-scaling for webhook and worker services

**Webhook Service Scaling**:
- Min: 1, Max: 2 (Starter) → 6 (Production)
- Metric: ALB RequestCountPerTarget
- Target: 100 requests per target per minute
- Scale-out cooldown: 60 seconds
- Scale-in cooldown: 300 seconds

**Worker Service Scaling**:
- Min: 1, Max: 2 (Starter) → 10 (Production)
- Metric: Redis queue depth (custom CloudWatch metric)
- Scale-out: Queue depth > 50 for 2 minutes
- Scale-in: Queue depth < 10 for 10 minutes
- Scale-out cooldown: 60 seconds
- Scale-in cooldown: 300 seconds

**Custom Metric for Queue Depth**:
Deploy a Lambda function or CloudWatch agent to publish Redis queue depth to CloudWatch every minute.

---

### 4.15 Step 14: Backup Configuration

**Action**: Configure backups for all stateful components

**RDS Backups**:
- Automated snapshots: Daily
- Retention: 7 days (Starter) → 35 days (Production)
- Backup window: 03:00-05:00 UTC
- PITR: Enabled

**Redis Backups**:
- Snapshot retention: 1 day (Starter) → 7 days (Production)
- Snapshot window: 03:00-04:00 UTC

**EFS Backups** (if used):
- AWS Backup: Daily
- Retention: 7 days

---

### 4.16 Terraform Module Structure

**Recommended Structure**:
```
modules/
└── n8n/
    ├── main.tf              # Main ECS service
    ├── webhook.tf           # Webhook ECS service
    ├── worker.tf            # Worker ECS service
    ├── rds.tf               # RDS PostgreSQL
    ├── redis.tf             # ElastiCache Redis
    ├── efs.tf               # EFS (optional)
    ├── security_groups.tf   # All security groups
    ├── iam.tf               # Task and execution roles
    ├── secrets.tf           # Secrets Manager
    ├── alb.tf               # ALB listener rules
    ├── autoscaling.tf       # Auto-scaling policies
    ├── monitoring.tf        # CloudWatch alarms
    ├── variables.tf         # Input variables
    └── outputs.tf           # Output values

environments/
├── qa/
│   └── n8n.tf               # n8n module with Starter config
└── prod/
    └── n8n.tf               # n8n module with Production config
```

**Key Variables for Scaling**:
```hcl
variable "scaling_tier" {
  type    = string
  default = "starter"  # starter, growth, production
}

variable "main_desired_count" { default = 1 }
variable "webhook_desired_count" { default = 1 }
variable "webhook_max_count" { default = 2 }
variable "worker_desired_count" { default = 1 }
variable "worker_max_count" { default = 2 }
variable "rds_instance_class" { default = "db.t3.micro" }
variable "redis_node_type" { default = "cache.t3.micro" }
variable "rds_multi_az" { default = false }
```

---

## 5. Scaling the Unified Architecture

### 5.1 Scaling Overview

The unified architecture scales by adjusting Terraform variables—no architectural changes required.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           SCALING PATH                                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│   STARTER                    GROWTH                      PRODUCTION              │
│   (~$180/mo)                 (~$350/mo)                  (~$800-1000/mo)         │
│                                                                                  │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │ Just change these Terraform variables:                                  │   │
│   │                                                                          │   │
│   │   main_desired_count:    1  →  1  →  2                                  │   │
│   │   webhook_max_count:     2  →  4  →  6                                  │   │
│   │   worker_max_count:      2  →  4  →  10                                 │   │
│   │   rds_instance_class:    db.t3.micro → db.t3.small → db.r6g.large       │   │
│   │   rds_multi_az:          false → false → true                           │   │
│   │   redis_node_type:       cache.t3.micro → t3.small → r6g.large         │   │
│   │   redis_cluster_mode:    false → false → true                           │   │
│   │                                                                          │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│   ✅ terraform apply - Rolling update, zero downtime                            │
│   ✅ No data migration                                                          │
│   ✅ No service reconfiguration                                                 │
│   ✅ No new infrastructure patterns                                             │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Cost Breakdown by Tier

**Starter Tier (~$180/month)**:

| Component | Configuration | Monthly Cost |
|-----------|--------------|--------------|
| n8n Main | 1 × 512 CPU, 1GB | ~$15 |
| n8n Webhook | 1 × 256 CPU, 512MB | ~$8 |
| n8n Worker | 1 × 512 CPU, 1GB | ~$15 |
| RDS PostgreSQL | db.t3.micro | ~$15 |
| ElastiCache Redis | cache.t3.micro | ~$12 |
| NAT Gateway | Existing (shared) | ~$0 |
| ALB | Existing (shared) | ~$5 |
| Data Transfer | ~10 GB | ~$5 |
| CloudWatch | Logs, metrics | ~$10 |
| Secrets Manager | 5 secrets | ~$2 |
| **Total** | | **~$87** |

*Note: Add ~$100 for reserved capacity buffers and unexpected usage = ~$180*

**Growth Tier (~$350/month)**:

| Component | Configuration | Monthly Cost |
|-----------|--------------|--------------|
| n8n Main | 1 × 1024 CPU, 2GB | ~$30 |
| n8n Webhook | 2 × 512 CPU, 1GB (avg) | ~$30 |
| n8n Worker | 2 × 1024 CPU, 2GB (avg) | ~$60 |
| RDS PostgreSQL | db.t3.small | ~$30 |
| ElastiCache Redis | cache.t3.small | ~$25 |
| Data Transfer | ~50 GB | ~$10 |
| CloudWatch | Enhanced | ~$20 |
| **Total** | | **~$350** |

**Production Tier (~$800-1000/month)**:

| Component | Configuration | Monthly Cost |
|-----------|--------------|--------------|
| n8n Main | 2 × 1024 CPU, 2GB | ~$60 |
| n8n Webhook | 3 × 512 CPU, 1GB (avg) | ~$45 |
| n8n Worker | 4 × 1024 CPU, 2GB (avg) | ~$120 |
| RDS PostgreSQL | db.r6g.large, Multi-AZ | ~$350 |
| ElastiCache Redis | cache.r6g.large, cluster | ~$300 |
| Data Transfer | ~100 GB | ~$20 |
| CloudWatch | Full monitoring | ~$40 |
| **Total** | | **~$935** |

### 5.3 When to Scale

**Scale from Starter to Growth when**:
- Workflow executions > 100/hour consistently
- Worker CPU > 70% during peak
- Redis memory > 60%
- User count > 5

**Scale from Growth to Production when**:
- Workflow executions > 500/hour
- Reliability SLA required (99.9%+)
- Worker queue depth frequently > 50
- Multiple teams depend on n8n
- Any downtime causes business impact

### 5.4 Scaling Procedure

**Step 1**: Update Terraform variables
```hcl
# environments/qa/n8n.tf
module "n8n" {
  source = "../../modules/n8n"

  # Change from starter to growth
  scaling_tier        = "growth"
  rds_instance_class  = "db.t3.small"
  redis_node_type     = "cache.t3.small"
  worker_max_count    = 4
  webhook_max_count   = 4
}
```

**Step 2**: Run Terraform plan
```bash
cd environments/qa && terraform plan
```

**Step 3**: Review changes
- Verify only expected resources change
- Check for any destructive operations
- RDS instance class change = brief I/O pause

**Step 4**: Apply during low-traffic window
```bash
terraform apply
```

**Step 5**: Verify
- Check ECS services healthy
- Verify workflows execute correctly
- Monitor CloudWatch for errors

### 5.5 Scaling Database Considerations

**RDS Instance Class Changes**:
- Single-AZ: Brief I/O pause (~30 seconds)
- Multi-AZ: Failover to standby, minimal impact

**Enabling Multi-AZ**:
- Can be done without downtime
- Takes 15-30 minutes to create standby
- Doubles cost

**Storage Scaling**:
- Storage can only increase, not decrease
- Enable autoscaling: `max_allocated_storage = 500`

### 5.6 Redis Scaling Considerations

**Node Type Changes**:
- Cluster mode disabled: Creates new node, brief unavailability
- Schedule during low-traffic window

**Enabling Cluster Mode**:
- Requires new cluster creation
- Data migration required
- Plan for 30-60 minute migration window
- Do this BEFORE you need it (at Growth tier)

---

## 6. Security & Compliance Considerations

### 6.1 Access Control Models

**Network Level**:
- n8n runs in private subnets only
- No direct internet access to instances
- ALB terminates HTTPS
- Outbound traffic via NAT Gateway

**Application Level**:
- Basic authentication (minimum)
- SAML/LDAP integration (if enterprise)
- API key authentication for external integrations
- Webhook authentication (per workflow)

**AWS Level**:
- IAM roles with least privilege
- No hardcoded credentials
- Secrets Manager for sensitive data
- KMS for encryption keys

### 6.2 Network Isolation

**Security Group Rules**:

| Resource | Inbound | Outbound |
|----------|---------|----------|
| n8n Main SG | Port 5678 from ALB SG | All to 0.0.0.0/0 |
| n8n Webhook SG | Port 5678 from ALB SG | All to 0.0.0.0/0 |
| n8n Worker SG | None (no inbound) | All to 0.0.0.0/0 |
| Redis SG | Port 6379 from n8n SGs | None |
| RDS SG | Port 5432 from n8n SGs | None |

**VPC Endpoints**:
Leverage existing VPC endpoints for:
- ECR (docker pull without internet)
- Secrets Manager (credentials without internet)
- CloudWatch Logs (logging without internet)
- S3 (if using S3 for binary storage)

### 6.3 Auditability

**What to Log**:
- All authentication attempts (success/failure)
- Workflow creation, modification, deletion
- Credential access and usage
- Execution start/end with status
- Administrative actions

**Log Retention**:
- All logs retained for 2192 days (6 years)
- Consistent with HIPAA requirements
- Lifecycle: Standard → Standard-IA (90d) → Glacier (365d)

**Audit Trail**:
- CloudTrail logs all API calls to AWS
- VPC Flow Logs capture network traffic
- RDS activity logs for database access

### 6.4 HIPAA Alignment

If n8n workflows process PHI (Protected Health Information):

**Required Controls**:
- [ ] Encryption at rest (EFS, RDS, Redis)
- [ ] Encryption in transit (TLS 1.2+)
- [ ] Access logging enabled
- [ ] Audit trails maintained
- [ ] 6-year log retention
- [ ] Access limited to authorized personnel
- [ ] BAA in place with AWS (organizational level)

**Workflow Guidelines**:
- Do not log PHI in workflow output
- Use encrypted credentials for external systems
- Implement data minimization in integrations
- Document data flows involving PHI

---

## 7. Operational Playbooks (Conceptual)

### 7.1 Upgrade Procedure

**Version Upgrade Process**:

1. **Preparation**:
   - Review n8n release notes
   - Check for breaking changes
   - Test upgrade in QA environment
   - Backup database

2. **Execution**:
   - Update ECR image tag in Terraform
   - Apply Terraform in QA
   - Verify QA functionality
   - Apply Terraform in Production
   - Monitor for errors

3. **Rollback Criteria**:
   - Error rate > 5%
   - Any critical functionality broken
   - Database migration issues

4. **Rollback Process**:
   - Revert Terraform to previous image tag
   - Apply Terraform
   - Verify previous version functionality
   - Document issue for investigation

### 7.2 Failure Handling

**Scenario: Worker Not Processing Jobs**:
1. Check ECS service status
2. Check CloudWatch logs for errors
3. Verify Redis connectivity
4. Check database connectivity
5. Force new deployment if stuck

**Scenario: High Error Rate**:
1. Check CloudWatch dashboard
2. Identify error patterns in logs
3. Check external integration status
4. Check database performance
5. Scale workers if queue backup

**Scenario: Database Connection Issues**:
1. Check RDS metrics (connections, CPU)
2. Verify security group rules
3. Check RDS Proxy status (if used)
4. Restart application if connections exhausted
5. Scale RDS if persistent issue

### 7.3 Scaling Decision Framework

**When to Scale Out**:
- Queue depth > 100 for > 5 minutes
- Worker CPU > 80% sustained
- Webhook latency > 2 seconds

**When to Scale Up (Vertical)**:
- Consistent memory pressure
- Complex workflows failing with OOM
- Single workflow execution time degrading

**When to Optimize Before Scaling**:
- Review workflow efficiency
- Check for unnecessary loops
- Optimize database queries in workflows
- Consider async patterns

### 7.4 Rollback Procedures

**Application Rollback**:
1. Identify previous working image tag
2. Update Terraform configuration
3. Apply Terraform (rolling deployment)
4. Verify functionality

**Database Rollback** (if needed):
1. Stop n8n services
2. Restore RDS from point-in-time backup
3. Update application to point to restored instance
4. Restart n8n services
5. Verify data consistency

**Configuration Rollback**:
1. Use Terraform Cloud state history
2. Identify last known good state
3. Apply rollback plan
4. Verify functionality

---

## 8. Decision Traceability

### 8.1 Compute Platform: ECS Fargate vs EKS

| Factor | ECS Fargate | EKS |
|--------|-------------|-----|
| Consistency with existing infra | ✅ Matches current pattern | ❌ New pattern |
| Operational complexity | ✅ Lower | ❌ Higher |
| Official n8n documentation | ❌ Not documented | ✅ Documented |
| Team expertise | ✅ Existing | ❌ Requires learning |
| Base cost | ✅ Lower (no control plane) | ❌ Higher |

**Decision**: ECS Fargate
**Trade-off**: Accepting lack of official documentation in favor of operational consistency
**Revisit When**: Team gains Kubernetes expertise or n8n releases ECS documentation

### 8.2 Database: RDS PostgreSQL vs Aurora PostgreSQL

| Factor | RDS PostgreSQL | Aurora PostgreSQL |
|--------|----------------|-------------------|
| Cost | ✅ Lower | ❌ Higher |
| Scaling | ✅ Sufficient | ✅ Better |
| Operational simplicity | ✅ Simpler | ❌ More complex |
| Performance | ✅ Adequate | ✅ Better |

**Decision**: RDS PostgreSQL
**Trade-off**: Lower cost at expense of advanced scaling features
**Revisit When**: Database becomes bottleneck, read replica needed

### 8.3 Redis: ElastiCache vs Self-Managed

| Factor | ElastiCache | Self-Managed on ECS |
|--------|-------------|---------------------|
| Operational burden | ✅ AWS managed | ❌ Self-managed |
| Cost | ❌ Higher | ✅ Lower |
| Reliability | ✅ Higher | ❌ Lower |
| Cluster mode | ✅ Native support | ❌ Complex |

**Decision**: ElastiCache
**Trade-off**: Higher cost for reduced operational burden
**Revisit When**: Cost optimization needed, team has Redis expertise

### 8.4 Architecture: Phased vs Unified

| Factor | Phased Approach | Unified Approach |
|--------|-----------------|------------------|
| Initial cost | ✅ Lower (~$20/mo) | ❌ Higher (~$180/mo) |
| Total Year 1 cost | ❌ Higher (~$11k) | ✅ Lower (~$4.4k) |
| Migration risk | ❌ High (2 migrations) | ✅ None |
| Operational complexity | ❌ Changes over time | ✅ Consistent |
| Time to production readiness | ❌ Longer | ✅ Immediate |

**Decision**: Unified Architecture (Production-ready from Day 1)
**Trade-off**: Higher initial monthly cost for zero migration complexity
**Revisit When**: Never - this is the recommended pattern

---

## 9. Final Checklists

### 9.1 Starter Tier Readiness Checklist

**Infrastructure**:
- [ ] RDS PostgreSQL deployed
- [ ] ElastiCache Redis deployed
- [ ] ECS services deployed (main, webhook, worker)
- [ ] ALB listener rules configured
- [ ] Security groups in place
- [ ] IAM roles with appropriate permissions

**Networking**:
- [ ] DNS records resolve correctly
- [ ] HTTPS working with valid certificate
- [ ] Health checks passing on all services

**Security**:
- [ ] Secrets stored in Secrets Manager
- [ ] Encryption key backed up securely
- [ ] No public IP on tasks

**Operations**:
- [ ] CloudWatch logs flowing (all services)
- [ ] Basic alarms configured
- [ ] RDS backups enabled
- [ ] Redis snapshots configured

**Validation**:
- [ ] Can log in to n8n UI
- [ ] Can create and execute workflow
- [ ] Queue mode working (jobs processed by workers)
- [ ] Webhooks receivable via external URL

### 9.2 Production Tier Readiness Checklist

**High Availability**:
- [ ] Multi-AZ deployment (all components)
- [ ] RDS Multi-AZ enabled
- [ ] Redis cluster with replicas
- [ ] Auto-scaling configured
- [ ] Minimum 2 tasks for main service

**Reliability**:
- [ ] Worker scaling based on queue depth
- [ ] Webhook scaling based on request count
- [ ] Health checks tuned for fast failover
- [ ] Deletion protection on RDS

**Security**:
- [ ] Secrets rotation documented
- [ ] All encryption enabled (at-rest, in-transit)
- [ ] VPC endpoints for AWS services
- [ ] Security groups minimized

**Compliance** (if HIPAA):
- [ ] 2192-day log retention configured
- [ ] Audit logging enabled
- [ ] Access logging enabled
- [ ] Encryption validated

**Disaster Recovery**:
- [ ] Backup procedures documented
- [ ] Recovery procedures documented
- [ ] Recovery tested (at least database restore)
- [ ] Runbook available to on-call

**Monitoring**:
- [ ] Comprehensive dashboard created
- [ ] Alarms for all critical metrics
- [ ] Alerts route to appropriate team
- [ ] Log queries prepared for troubleshooting

### 9.3 Scaling Readiness Checklist

**Before Scaling Up**:
- [ ] Current tier metrics analyzed
- [ ] Bottleneck identified (compute, database, redis)
- [ ] Terraform variables prepared for new tier
- [ ] Change scheduled during low-traffic window

**Before Enabling Redis Cluster Mode**:
- [ ] Data migration plan documented
- [ ] Maintenance window scheduled (30-60 min)
- [ ] Rollback plan prepared
- [ ] Team notified

**Before Enabling RDS Multi-AZ**:
- [ ] Cost impact understood (doubles RDS cost)
- [ ] No action needed (live migration)

---

## Appendix: Reference Links

- [n8n Self-Hosting Documentation](https://docs.n8n.io/hosting/)
- [n8n AWS Hosting Guide](https://docs.n8n.io/hosting/installation/server-setups/aws/)
- [n8n Scaling Documentation](https://docs.n8n.io/hosting/scaling/)
- [n8n Environment Variables](https://docs.n8n.io/hosting/configuration/environment-variables/)
- [n8n Queue Mode](https://docs.n8n.io/hosting/scaling/queue-mode/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

*Document Version: 2.0 (Unified Architecture)*
*Last Updated: December 2025*
*Author: Infrastructure Team*
