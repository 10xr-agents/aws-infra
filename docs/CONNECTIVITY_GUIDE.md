# Connectivity Guide

This guide explains how to securely connect to AWS resources (DocumentDB, Redis, ECS services) from your local machine using the bastion host.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Enable Bastion Host](#enable-bastion-host)
- [Connect to Bastion Host](#connect-to-bastion-host)
- [Connect to DocumentDB](#connect-to-documentdb)
- [Connect to Redis](#connect-to-redis)
- [Port Forwarding](#port-forwarding)
- [Disable Bastion Host](#disable-bastion-host)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### 1. Install AWS CLI v2

```bash
# macOS
brew install awscli

# Verify installation
aws --version
```

### 2. Install Session Manager Plugin

The Session Manager plugin is required for SSM connections:

```bash
# macOS
brew install --cask session-manager-plugin

# Verify installation
session-manager-plugin --version
```

### 3. Configure AWS Credentials

```bash
# Configure your AWS credentials
aws configure

# Or use SSO
aws configure sso

# Verify access
aws sts get-caller-identity
```

### 4. Install Database Clients (Optional - for local connections)

```bash
# MongoDB Shell (for DocumentDB)
brew install mongosh

# Redis CLI
brew install redis

# Download DocumentDB CA certificate
mkdir -p ~/.documentdb
wget -O ~/.documentdb/global-bundle.pem \
  https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
```

---

## Enable Bastion Host

The bastion host is disabled by default to save costs. Enable it when you need to access AWS resources.

### Option 1: Via Terraform Cloud UI

1. Go to [Terraform Cloud](https://app.terraform.io/app/10XR/workspaces)
2. Select the workspace (e.g., `qa-us-east-1-ten-xr-app`)
3. Go to **Variables**
4. Add or update: `enable_bastion_host = true`
5. Click **Start new run** → **Apply**

### Option 2: Via Terraform CLI

```bash
cd environments/qa

# Create a terraform.tfvars file or update existing
echo 'enable_bastion_host = true' >> terraform.tfvars

# Apply the changes
terraform apply -var="enable_bastion_host=true"
```

### Verify Bastion is Running

```bash
# Get the bastion instance ID
terraform output bastion_instance_id

# Or check via AWS CLI
aws ec2 describe-instances \
  --filters "Name=tag:Component,Values=Bastion" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table \
  --region us-east-1
```

---

## Connect to Bastion Host

### Direct Shell Access

Connect directly to the bastion host shell via SSM Session Manager:

```bash
# Get the instance ID from Terraform output
BASTION_ID=$(terraform output -raw bastion_instance_id)

# Start SSM session
aws ssm start-session --target $BASTION_ID --region us-east-1
```

Or use the command from Terraform output:

```bash
terraform output -raw bastion_ssm_command
```

### What's Pre-installed on Bastion

The bastion host comes with these tools pre-installed:

- `mongosh` - MongoDB shell for DocumentDB
- `redis6-cli` - Redis CLI
- `postgresql15` - PostgreSQL client
- `mysql` - MySQL client
- `jq`, `wget`, `curl`, `telnet`, `nc` - Utilities

The DocumentDB CA certificate is pre-downloaded at:
```
/home/ec2-user/.documentdb/global-bundle.pem
```

---

## Connect to DocumentDB

### Method 1: Connect from Bastion Host (Recommended)

1. **Start SSM session to bastion:**
   ```bash
   BASTION_ID=$(terraform output -raw bastion_instance_id)
   aws ssm start-session --target $BASTION_ID --region us-east-1
   ```

2. **Get DocumentDB credentials from Secrets Manager:**
   ```bash
   # On the bastion host
   aws secretsmanager get-secret-value \
     --secret-id ten-xr-app-qa-documentdb-credentials \
     --query 'SecretString' \
     --output text \
     --region us-east-1 | jq .
   ```

3. **Connect using the helper script:**
   ```bash
   # On the bastion host
   ./connect-documentdb.sh <endpoint> <username> <password> <database>

   # Example:
   ./connect-documentdb.sh \
     ten-xr-app-qa-docdb.cluster-xxxx.us-east-1.docdb.amazonaws.com \
     docdbadmin \
     'your-password' \
     ten_xr_agents_qa
   ```

4. **Or connect manually:**
   ```bash
   mongosh "mongodb://docdbadmin:<password>@<endpoint>:27017/ten_xr_agents_qa?tls=true&tlsCAFile=/home/ec2-user/.documentdb/global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
   ```

### Method 2: Port Forwarding (Connect from Local Machine)

Use SSM port forwarding to access DocumentDB from your local machine:

1. **Get DocumentDB endpoint:**
   ```bash
   terraform output documentdb_endpoint
   ```

2. **Start port forwarding:**
   ```bash
   BASTION_ID=$(terraform output -raw bastion_instance_id)
   DOCDB_ENDPOINT=$(terraform output -raw documentdb_endpoint)

   aws ssm start-session \
     --target $BASTION_ID \
     --document-name AWS-StartPortForwardingSessionToRemoteHost \
     --parameters "{\"host\":[\"$DOCDB_ENDPOINT\"],\"portNumber\":[\"27017\"],\"localPortNumber\":[\"27017\"]}" \
     --region us-east-1
   ```

3. **Connect locally (in another terminal):**
   ```bash
   mongosh "mongodb://docdbadmin:<password>@localhost:27017/ten_xr_agents_qa?tls=true&tlsCAFile=~/.documentdb/global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false&tlsAllowInvalidHostnames=true"
   ```

   > **Note:** Add `&tlsAllowInvalidHostnames=true` when connecting via port forwarding since the certificate is issued for the actual endpoint, not localhost.

### Using GUI Tools (MongoDB Compass, Studio 3T)

1. Start port forwarding (see above)
2. Configure connection in your GUI tool:
   - **Host:** `localhost`
   - **Port:** `27017`
   - **Authentication:** Username/Password
   - **Username:** `docdbadmin`
   - **Password:** (from Secrets Manager)
   - **TLS/SSL:** Enabled
   - **CA File:** `~/.documentdb/global-bundle.pem`
   - **Allow Invalid Hostnames:** Yes

---

## Connect to Redis

### Method 1: Connect from Bastion Host

```bash
# Start SSM session
aws ssm start-session --target $BASTION_ID --region us-east-1

# On bastion, use the helper script
./connect-redis.sh <redis-endpoint> 6379 <auth-token>

# Or manually
redis6-cli -h <redis-endpoint> -p 6379 --tls -a <auth-token>
```

### Method 2: Port Forwarding

```bash
BASTION_ID=$(terraform output -raw bastion_instance_id)
REDIS_ENDPOINT="<your-redis-endpoint>"

aws ssm start-session \
  --target $BASTION_ID \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$REDIS_ENDPOINT\"],\"portNumber\":[\"6379\"],\"localPortNumber\":[\"6379\"]}" \
  --region us-east-1
```

Then connect locally:
```bash
redis-cli -h localhost -p 6379 --tls -a <auth-token>
```

---

## Port Forwarding

### Generic Port Forwarding Command

```bash
aws ssm start-session \
  --target <BASTION_INSTANCE_ID> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<REMOTE_HOST>"],"portNumber":["<REMOTE_PORT>"],"localPortNumber":["<LOCAL_PORT>"]}' \
  --region us-east-1
```

### Common Port Forwarding Scenarios

| Service | Remote Port | Local Port | Example Host |
|---------|-------------|------------|--------------|
| DocumentDB | 27017 | 27017 | `*.docdb.amazonaws.com` |
| Redis | 6379 | 6379 | `*.cache.amazonaws.com` |
| PostgreSQL | 5432 | 5432 | `*.rds.amazonaws.com` |
| MySQL | 3306 | 3306 | `*.rds.amazonaws.com` |
| Internal ALB | 443 | 8443 | `internal-*.elb.amazonaws.com` |

---

## Disable Bastion Host

When you're done, disable the bastion host to save costs:

### Option 1: Via Terraform Cloud UI

1. Go to workspace variables
2. Set `enable_bastion_host = false`
3. Apply changes

### Option 2: Via Terraform CLI

```bash
terraform apply -var="enable_bastion_host=false"
```

### Cost Savings

| Resource | Hourly Cost | Monthly Cost (24/7) |
|----------|-------------|---------------------|
| t3.micro | ~$0.0104 | ~$7.50 |
| t3.small | ~$0.0208 | ~$15.00 |
| t3.medium | ~$0.0416 | ~$30.00 |

> **Tip:** Only enable the bastion when needed. For occasional access, costs will be minimal.

---

## Troubleshooting

### SSM Session Won't Start

1. **Check instance is running:**
   ```bash
   aws ec2 describe-instances --instance-ids $BASTION_ID \
     --query 'Reservations[].Instances[].State.Name' --output text
   ```

2. **Check SSM agent status:**
   ```bash
   aws ssm describe-instance-information \
     --filters "Key=InstanceIds,Values=$BASTION_ID" \
     --query 'InstanceInformationList[].PingStatus' --output text
   ```

   Should return `Online`. If not, the instance may still be starting up (wait 2-3 minutes).

3. **Check IAM permissions:**
   Ensure your IAM user/role has these permissions:
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "ssm:StartSession",
       "ssm:TerminateSession",
       "ssm:ResumeSession"
     ],
     "Resource": "*"
   }
   ```

### Cannot Connect to DocumentDB

1. **Check security groups:**
   The bastion's security group needs outbound access to DocumentDB's security group on port 27017.

2. **Verify endpoint:**
   ```bash
   terraform output documentdb_endpoint
   ```

3. **Test connectivity from bastion:**
   ```bash
   # On bastion
   nc -zv <documentdb-endpoint> 27017
   ```

4. **Check credentials:**
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id ten-xr-app-qa-documentdb-credentials \
     --region us-east-1
   ```

### Port Forwarding Fails

1. **Check if port is already in use locally:**
   ```bash
   lsof -i :27017
   ```

2. **Use a different local port:**
   ```bash
   # Use local port 27018 instead
   --parameters '{"host":["..."],"portNumber":["27017"],"localPortNumber":["27018"]}'
   ```

3. **Check Session Manager plugin:**
   ```bash
   session-manager-plugin --version
   ```

### TLS Certificate Errors

1. **Ensure CA certificate is downloaded:**
   ```bash
   # Local machine
   ls -la ~/.documentdb/global-bundle.pem

   # On bastion
   ls -la /home/ec2-user/.documentdb/global-bundle.pem
   ```

2. **Re-download if missing:**
   ```bash
   wget -O ~/.documentdb/global-bundle.pem \
     https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
   ```

3. **For port forwarding, add hostname exception:**
   ```
   &tlsAllowInvalidHostnames=true
   ```

---

## Quick Reference

### One-liner: Connect to DocumentDB

```bash
# Start port forwarding in background, then connect
BASTION_ID=$(cd environments/qa && terraform output -raw bastion_instance_id) && \
DOCDB=$(cd environments/qa && terraform output -raw documentdb_endpoint) && \
aws ssm start-session --target $BASTION_ID --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$DOCDB\"],\"portNumber\":[\"27017\"],\"localPortNumber\":[\"27017\"]}" \
  --region us-east-1
```

### Useful Terraform Outputs

```bash
cd environments/qa

# Get all bastion info
terraform output bastion_connection_info

# Individual outputs
terraform output bastion_instance_id
terraform output bastion_ssm_command
terraform output documentdb_endpoint
terraform output documentdb_connection_info
```

### Environment-specific Endpoints

| Environment | DocumentDB Endpoint | Secrets Manager ARN |
|-------------|---------------------|---------------------|
| QA | `terraform output -raw documentdb_endpoint` | `ten-xr-app-qa-documentdb-credentials` |
| Prod | `terraform output -raw documentdb_endpoint` | `ten-xr-app-prod-documentdb-credentials` |

---

## Security Best Practices

1. **Disable bastion when not in use** - Reduces attack surface and costs
2. **Never store credentials locally** - Always fetch from Secrets Manager
3. **Use SSM Session Manager** - No SSH keys to manage, all sessions logged
4. **Rotate credentials regularly** - DocumentDB credentials should be rotated periodically
5. **Review session logs** - CloudWatch logs all SSM sessions for audit

---

## Additional Resources

- [AWS SSM Session Manager Documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [DocumentDB Connection Guide](https://docs.aws.amazon.com/documentdb/latest/developerguide/connect-from-outside-a-vpc.html)
- [Session Manager Plugin Installation](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
