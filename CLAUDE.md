# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AWS infrastructure repository for 10xR Healthcare platform services using Terraform. Manages ECS Fargate deployments, VPC networking, load balancers, Redis caching, and supporting infrastructure.

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

### Terraform Cloud UI
- **URL**: https://app.terraform.io/app/10XR/workspaces
- Plans and applies can be triggered and monitored from the TFC UI
- Variables (including sensitive ones like `cloudflare_api_token`) are configured in workspace settings

## Architecture

### Directory Structure

- **environments/**: Environment-specific configurations (qa, prod)
  - Each environment has `main.tf`, `variables.tf`, `locals.tf`, `outputs.tf`, `terraform.tfvars`
  - `locals.tf` contains environment-specific overrides and IAM policies
- **modules/**: Reusable infrastructure modules
  - `vpc/`: VPC with public/private/database subnets, NAT gateways, VPC endpoints
  - `ecs/`: ECS Fargate cluster, services, task definitions, ALB, auto-scaling
  - `networking/`: NLB (Network Load Balancer), target groups, listeners
  - `redis/`: ElastiCache Redis replication group with auth and encryption
  - `certs/`: ACM certificate management with DNS validation

### Traffic Flow

1. **External Traffic** -> NLB (public-facing) -> ALB (internal) -> ECS Services
2. Services use host-based routing via ALB (e.g., `api.qa.10xr.co`, `agents.qa.10xr.co`)
3. Production includes Global Accelerator -> NLB -> ALB -> ECS

### ECS Service Configuration

Services are defined in `terraform.tfvars` under `ecs_services` map. Each service configuration includes:
- Container image and tag
- CPU/memory allocation
- Capacity provider strategy (FARGATE vs FARGATE_SPOT)
- Health checks (container-level and ALB-level)
- Auto-scaling configuration
- ALB routing rules (host headers, path patterns)

The `locals.tf` in each environment merges service configs with environment-specific overrides (Redis connection, MongoDB credentials, IAM policies).

### Key Patterns

- **Naming Convention**: `${cluster_name}-${environment}` prefix for all resources
- **Tagging**: All resources tagged with Environment, Project, Component, Platform, Terraform
- **Secrets**: MongoDB and Redis credentials stored in AWS Secrets Manager/SSM Parameter Store
- **Service Discovery**: Private DNS namespace for inter-service communication (`{service}.{cluster}-{env}.local`)

## Environment Differences

**QA**:
- Single region (us-east-1)
- MongoDB on DigitalOcean (connection string in locals)
- Redis module may be commented out

**Production**:
- Global Accelerator for global routing
- Cloudflare DNS integration
- MongoDB Atlas with secrets from Secrets Manager
- Full Redis deployment with HA

## Important Notes

- VPC module uses `terraform-aws-modules/vpc/aws` (v5.17)
- VPC endpoints configured for ECR, ECS, SSM, Secrets Manager (reduces NAT costs)
- ACM certificates use DNS validation via Cloudflare
- ECS tasks use awsvpc networking mode with private subnets
- Redis uses transit and at-rest encryption with auth token