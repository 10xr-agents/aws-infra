# aws-infra

AWS infrastructure for 10xR Healthcare platform services using Terraform.

## Terraform Cloud

This project uses **Terraform Cloud** for remote state management and execution.

| Setting | Value |
|---------|-------|
| Organization | `10XR` |
| Project | `10XR AWS Infra` |
| QA Workspace | `qa-us-east-1-ten-xr-app` |
| Prod Workspace | `prod-us-east-1-ten-xr-app` |

### Getting Started

1. **Login to Terraform Cloud**
   ```bash
   terraform login
   ```

2. **Initialize the environment**
   ```bash
   cd environments/qa   # or environments/prod
   terraform init
   ```

3. **Plan and Apply**
   ```bash
   terraform plan
   terraform apply
   ```

### Terraform Cloud UI

Access workspaces at: https://app.terraform.io/app/10XR/workspaces

- Configure workspace variables (AWS credentials, Cloudflare API token)
- Monitor plan/apply runs
- View state and outputs

## Project Structure

```
aws-infra/
├── environments/
│   ├── qa/                 # QA environment configuration
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── locals.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   ├── versions.tf
│   │   └── terraform.tfvars
│   └── prod/               # Production environment configuration
│       └── ...
└── modules/
    ├── vpc/                # VPC, subnets, NAT gateways, VPC endpoints
    ├── ecs/                # ECS Fargate cluster, services, ALB
    ├── networking/         # NLB, target groups, listeners
    ├── redis/              # ElastiCache Redis
    └── certs/              # ACM certificates
```

## Environments

| Environment | Region | Workspace |
|-------------|--------|-----------|
| QA | us-east-1 | `qa-us-east-1-ten-xr-app` |
| Production | us-east-1 | `prod-us-east-1-ten-xr-app` |

## Services

Services are defined in `terraform.tfvars` under the `ecs_services` map:

- `voice-agent` - Voice agent service
- `livekit-proxy` - LiveKit proxy service
- `agent-analytics` - Analytics service
- `ui-console` - Web UI console
- `agentic-services` - Agentic framework service
- `automation-service-mcp` - Automation MCP service

## Common Commands

```bash
# Format all Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# View current state
terraform show

# List all resources
terraform state list
```