# MongoDB Cluster Module

This Terraform module creates a production-grade, self-hosted MongoDB replica set on AWS EC2.

## Features

- **High Availability**: Deploys MongoDB as a replica set across multiple availability zones
- **Automated Setup**: Installs MongoDB, initializes replica set, and configures authentication
- **Persistent Storage**: Uses EBS volumes for data persistence with encryption
- **Security**: Configures security groups, IAM roles, and MongoDB authentication
- **Monitoring**: Optional CloudWatch monitoring and logging
- **Backup**: Automated EBS snapshots for backup
- **DNS**: Optional Route53 private DNS records
- **Flexible**: Highly parameterized for different environments

## Architecture

The module creates:
- EC2 instances running MongoDB (configured as a replica set)
- EBS volumes for data storage (encrypted by default)
- Security groups for network isolation
- IAM roles and instance profiles
- CloudWatch log groups (optional)
- Route53 private hosted zone and DNS records (optional)
- SSM Parameter Store entry for connection string (optional)

## Usage

### Basic Example

```hcl
module "mongodb" {
  source = "../../modules/mongodb"

  cluster_name = "myapp-mongodb"
  environment  = "qa"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  replica_count   = 3
  instance_type   = "t3.large"
  data_volume_size = 100
  
  mongodb_version = "7.0"
  mongodb_admin_username = var.mongodb_admin_username
  mongodb_admin_password = var.mongodb_admin_password
  
  key_name = "my-ssh-key"
  
  allowed_cidr_blocks = [module.vpc.vpc_cidr_block]
  
  tags = {
    Environment = "qa"
    Project     = "myapp"
  }
}
```

### Advanced Example with All Options

```hcl
module "mongodb" {
  source = "../../modules/mongodb"

  # Cluster identification
  cluster_name     = "myapp-mongodb"
  environment      = "production"
  replica_set_name = "rs0"

  # Network configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Instance configuration
  replica_count = 3
  instance_type = "m6i.xlarge"
  ami_id        = "ami-0abcdef1234567890"  # Custom AMI
  key_name      = "prod-ssh-key"

  # MongoDB configuration
  mongodb_version        = "7.0"
  mongodb_admin_username = var.mongodb_admin_username
  mongodb_admin_password = var.mongodb_admin_password
  mongodb_keyfile_content = var.mongodb_keyfile
  default_database       = "myapp"

  # Storage configuration
  root_volume_size       = 50
  data_volume_size       = 500
  data_volume_type       = "gp3"
  data_volume_iops       = 10000
  data_volume_throughput = 250

  # Security configuration
  create_security_group = true
  allowed_cidr_blocks   = [
    module.vpc.vpc_cidr_block,
    "10.0.0.0/8"
  ]
  additional_security_group_ids = [
    aws_security_group.app_servers.id
  ]
  allow_ssh         = true
  ssh_cidr_blocks   = ["10.0.0.0/16"]

  # Monitoring and logging
  enable_monitoring  = true
  log_retention_days = 30

  # DNS configuration
  create_dns_records = true
  private_domain     = "mongodb.internal"

  # Backup configuration
  backup_enabled        = true
  backup_schedule       = "cron(0 3 * * ? *)"
  backup_retention_days = 14

  # Additional features
  store_connection_string_in_ssm = true
  enable_encryption_at_rest      = true
  enable_audit_logging          = true

  tags = {
    Environment = "production"
    Project     = "myapp"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}
```

## Required Variables

| Name | Description | Type |
|------|-------------|------|
| `cluster_name` | Name prefix for the MongoDB cluster resources | `string` |
| `environment` | Environment name (e.g., dev, qa, prod) | `string` |
| `vpc_id` | ID of the VPC where MongoDB will be deployed | `string` |
| `subnet_ids` | List of subnet IDs where MongoDB instances will be deployed | `list(string)` |
| `key_name` | Name of the SSH key pair for EC2 instances | `string` |
| `mongodb_admin_password` | MongoDB admin password | `string` |

## Optional Variables

See [variables.tf](./variables.tf) for the complete list of configurable options.

## Outputs

| Name | Description |
|------|-------------|
| `instance_ids` | IDs of the MongoDB EC2 instances |
| `endpoints` | List of MongoDB endpoints (ip:port) |
| `connection_string` | MongoDB connection string |
| `replica_set_name` | Name of the MongoDB replica set |
| `security_group_id` | ID of the MongoDB security group |
| `primary_endpoint` | Primary MongoDB endpoint |

## Post-Deployment Steps

### 1. Complete Replica Set Configuration

For nodes other than the primary, you'll need to add them to the replica set:

```bash
# SSH into the primary node
ssh -i your-key.pem ubuntu@<primary-instance-ip>

# Connect to MongoDB
mongosh -u admin -p <admin-password> --authenticationDatabase admin

# Add other nodes to replica set
rs.add("secondary-1-ip:27017")
rs.add("secondary-2-ip:27017")

# Check replica set status
rs.status()
```

### 2. Create Application Users

```javascript
use myapp
db.createUser({
  user: "appuser",
  pwd: "apppassword",
  roles: [
    { role: "readWrite", db: "myapp" }
  ]
})
```

### 3. Configure Application Connection

Use the connection string output from the module:

```hcl
# In your application configuration
mongodb_uri = module.mongodb.connection_string
```

## Security Considerations

1. **Network Security**:
    - Instances are deployed in private subnets
    - Security groups restrict access to specified CIDR blocks
    - Consider using VPC peering or VPN for cross-VPC access

2. **Authentication**:
    - MongoDB authentication is enabled by default
    - Use strong passwords for admin accounts
    - Create separate users for applications with minimal required permissions

3. **Encryption**:
    - EBS volumes are encrypted by default
    - Consider enabling MongoDB encryption at rest for additional security
    - Use TLS/SSL for client connections in production

4. **Backup**:
    - Automated EBS snapshots are configured
    - Consider implementing mongodump for logical backups
    - Test restore procedures regularly

## Monitoring

When monitoring is enabled, the module sets up:
- CloudWatch Logs for MongoDB logs
- Basic EC2 metrics (CPU, memory, disk)
- Custom MongoDB metrics can be added via CloudWatch agent configuration

## Troubleshooting

### Common Issues

1. **Replica Set Not Initializing**:
    - Check security group rules allow communication between nodes
    - Verify all nodes can resolve each other's hostnames
    - Check MongoDB logs in `/data/mongodb/logs/mongod.log`

2. **Connection Issues**:
    - Ensure your application is in a subnet that can reach MongoDB
    - Verify security group rules
    - Check if MongoDB is listening on the correct interface

3. **Performance Issues**:
    - Monitor EBS volume performance metrics
    - Consider upgrading instance type or EBS volume type
    - Check MongoDB slow query logs

## License

This module is released under the MIT License.