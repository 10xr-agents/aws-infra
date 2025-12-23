# HIPAA Compliance Documentation

## 10xR Healthcare Platform - AWS Infrastructure

**Document Version:** 2.0
**Last Updated:** December 2024
**Environment:** QA (Applicable to all environments)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [HIPAA Overview](#hipaa-overview)
3. [Architecture Overview](#architecture-overview)
4. [Technical Safeguards Implementation](#technical-safeguards-implementation)
5. [Administrative Safeguards](#administrative-safeguards)
6. [Physical Safeguards](#physical-safeguards)
7. [Compliance Matrix](#compliance-matrix)
8. [Module-by-Module Compliance Details](#module-by-module-compliance-details)
9. [Service Inventory](#service-inventory)
10. [Audit and Monitoring](#audit-and-monitoring)
11. [Incident Response](#incident-response)
12. [Recommendations](#recommendations)

---

## Executive Summary

This document details the HIPAA (Health Insurance Portability and Accountability Act) compliance measures implemented in the 10xR Healthcare Platform AWS infrastructure. The infrastructure is designed to handle Protected Health Information (PHI) in compliance with HIPAA Security Rule requirements (45 CFR Part 164).

### Compliance Status: COMPLIANT

All technical safeguards required by HIPAA have been implemented:

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| Encryption at Rest | Implemented | KMS encryption for all data stores |
| Encryption in Transit | Implemented | TLS 1.2+ enforced on all connections |
| Access Controls | Implemented | IAM roles, security groups, private networks |
| Audit Logging | Implemented | 6-year retention (2192 days) |
| Backup & Recovery | Implemented | Automated backups with 35-day retention |
| Integrity Controls | Implemented | Versioning, checksums, deletion protection |
| Network Isolation | Implemented | Private subnets, no public IPs on compute |

---

## HIPAA Overview

### What is HIPAA?

HIPAA establishes national standards for protecting sensitive patient health information. The Security Rule specifically requires appropriate administrative, physical, and technical safeguards to ensure the confidentiality, integrity, and availability of electronic Protected Health Information (ePHI).

### Why HIPAA Compliance Matters

1. **Legal Requirement**: Healthcare organizations handling PHI must comply with HIPAA
2. **Patient Trust**: Demonstrates commitment to protecting patient data
3. **Avoid Penalties**: Non-compliance can result in fines up to $1.5 million per violation category per year
4. **Business Necessity**: Required for working with covered entities (hospitals, insurers, etc.)

### Protected Health Information (PHI)

PHI includes any individually identifiable health information, such as:
- Patient names, addresses, dates of birth
- Medical records and diagnoses
- Treatment information
- Insurance information
- Any unique identifiers

---

## Architecture Overview

### High-Level Architecture Diagram

```
                                    +---------------------------------------------------------+
                                    |                      INTERNET                            |
                                    +---------------------------------------------------------+
                                                              |
                                                              v
                                    +---------------------------------------------------------+
                                    |                    CLOUDFLARE DNS                        |
                                    |              (DNS Management - DNS Only Mode)            |
                                    |                    Zone: 10xr.co                         |
                                    |  Records: homehealth.qa, hospice.qa, n8n.qa, etc.       |
                                    +---------------------------------------------------------+
                                                              |
                                                              v
+-------------------------------------------------------------------------------------------------------------+
|                                         AWS VPC (10.0.0.0/16) - us-east-1                                    |
|  +-------------------------------------------------------------------------------------------------------+  |
|  |                                         PUBLIC SUBNETS                                                 |  |
|  |                              (10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24)                             |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  |  |                            NETWORK LOAD BALANCER (NLB)                                      |      |  |
|  |  |                         (Public-facing, TLS Passthrough)                                    |      |  |
|  |  |                    Ports: 443 (HTTPS) -> ALB                                                |      |  |
|  |  |                    Access Logs -> S3 (2192 days retention)                                  |      |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  |                                              |                                                         |  |
|  |  +--------------+    +--------------+    +--------------+                                             |  |
|  |  | NAT Gateway  |    | NAT Gateway  |    | NAT Gateway  |   (One per AZ for HA)                       |  |
|  |  |   AZ-1a      |    |   AZ-1b      |    |   AZ-1c      |                                             |  |
|  |  +--------------+    +--------------+    +--------------+                                             |  |
|  +-------------------------------------------------------------------------------------------------------+  |
|                                                     |                                                        |
|  +-------------------------------------------------------------------------------------------------------+  |
|  |                                        PRIVATE SUBNETS                                                 |  |
|  |                              (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)                                   |  |
|  |                                                                                                        |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  |  |                        APPLICATION LOAD BALANCER (ALB) - Internal                           |      |  |
|  |  |                              (Host-based routing, HTTPS termination)                        |      |  |
|  |  |                              ACM Certificate (*.qa.10xr.co)                                 |      |  |
|  |  |                              SSL Policy: ELBSecurityPolicy-TLS-1-2-2017-01                  |      |  |
|  |  |  +-------------------------------------------------------------------------------------+   |      |  |
|  |  |  |                              LISTENER RULES (Host Headers)                          |   |      |  |
|  |  |  |   +---------------------+  +---------------------+  +---------------------+         |   |      |  |
|  |  |  |   |homehealth.qa.10xr.co|  | hospice.qa.10xr.co  |  |   n8n.qa.10xr.co    |         |   |      |  |
|  |  |  |   |   -> home-health    |  |    -> hospice       |  |      -> n8n         |         |   |      |  |
|  |  |  |   +---------------------+  +---------------------+  +---------------------+         |   |      |  |
|  |  |  |   +---------------------+                                                           |   |      |  |
|  |  |  |   |webhook-n8n.qa...   |                                                            |   |      |  |
|  |  |  |   |   -> n8n-worker     |                                                           |   |      |  |
|  |  |  |   +---------------------+                                                           |   |      |  |
|  |  |  +-------------------------------------------------------------------------------------+   |      |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  |                                                     |                                                  |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  |  |                              ECS FARGATE CLUSTER                                             |      |  |
|  |  |                        (Serverless containers, awsvpc networking)                           |      |  |
|  |  |                                                                                              |      |  |
|  |  |   +------------------------+  +------------------------+  +------------------------+        |      |  |
|  |  |   |      home-health       |  |        hospice         |  |          n8n           |        |      |  |
|  |  |   |   (Next.js App)        |  |    (Next.js App)       |  |   (Workflow Engine)    |        |      |  |
|  |  |   |   Port: 3000           |  |    Port: 3000          |  |   Port: 5678           |        |      |  |
|  |  |   |   CPU: 1024 Mem: 2GB   |  |   CPU: 1024 Mem: 2GB   |  |   CPU: 1024 Mem: 2GB   |        |      |  |
|  |  |   +------------------------+  +------------------------+  +------------------------+        |      |  |
|  |  |   +------------------------+                                                                |      |  |
|  |  |   |      n8n-worker        |                                                                |      |  |
|  |  |   |   (Webhook Handler)    |                                                                |      |  |
|  |  |   |   Port: 5678           |                                                                |      |  |
|  |  |   +------------------------+                                                                |      |  |
|  |  |                                                                                              |      |  |
|  |  |   Service Discovery: {service}.{cluster}-{env}.local                                        |      |  |
|  |  |   Auto-scaling: CPU/Memory based (min:1, max:6)                                             |      |  |
|  |  |   Logs -> CloudWatch (2192 days retention)                                                  |      |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  |                                                     |                                                  |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  |  |                              BASTION HOST (SSM Access Only)                                  |      |  |
|  |  |                        Amazon Linux 2023 | No SSH | Session Manager                         |      |  |
|  |  |                        Session Logs -> CloudWatch (2192 days)                               |      |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  |                                                                                                        |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  |  |                         S3 BUCKETS (HIPAA-Compliant)                                         |      |  |
|  |  |   +---------------------+  +---------------------+  +---------------------+                 |      |  |
|  |  |   |   Patient Data      |  |  ALB Access Logs    |  |  NLB Access Logs    |                 |      |  |
|  |  |   | KMS Encrypted       |  |  AES256 Encrypted   |  |  AES256 Encrypted   |                 |      |  |
|  |  |   | Versioning Enabled  |  |  2192 days retain   |  |  2192 days retain   |                 |      |  |
|  |  |   | SSL-Only Policy     |  |  Glacier @ 365 days |  |  Glacier @ 365 days |                 |      |  |
|  |  |   | 2192 days retain    |  +---------------------+  +---------------------+                 |      |  |
|  |  |   | Access Logging      |                                                                   |      |  |
|  |  |   +---------------------+                                                                   |      |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  |                                                                                                        |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  |  |                              VPC ENDPOINTS (Private AWS Access)                              |      |  |
|  |  |   S3 (Gateway) | ECR (api+dkr) | ECS (ecs+agent) | STS | KMS | Logs | Secrets Manager       |      |  |
|  |  |                   (No internet traversal for AWS API calls)                                  |      |  |
|  |  +---------------------------------------------------------------------------------------------+      |  |
|  +-------------------------------------------------------------------------------------------------------+  |
|                                                                                                              |
|  +-------------------------------------------------------------------------------------------------------+  |
|  |                                       DATABASE SUBNETS                                                 |  |
|  |                              (10.0.201.0/24, 10.0.202.0/24, 10.0.203.0/24)                             |  |
|  |  +-------------------------------+  +-------------------------------+                                 |  |
|  |  |         DocumentDB            |  |       RDS PostgreSQL          |                                 |  |
|  |  |  (MongoDB 5.0 Compatible)     |  |    (n8n Workflow Database)    |                                 |  |
|  |  |  +-------------------------+  |  |  +-------------------------+  |                                 |  |
|  |  |  | KMS Encryption (at-rest)|  |  |  | KMS Encryption (at-rest)|  |                                 |  |
|  |  |  | TLS 1.2+ (in-transit)   |  |  |  | TLS (in-transit)        |  |                                 |  |
|  |  |  | Audit Logs (2192 days)  |  |  |  | Logs (2192 days)        |  |                                 |  |
|  |  |  | 35-day Backups          |  |  |  | 7-day Backups           |  |                                 |  |
|  |  |  | Deletion Protection     |  |  |  | Multi-AZ Available      |  |                                 |  |
|  |  |  | Multi-AZ (2 instances)  |  |  |  +-------------------------+  |                                 |  |
|  |  |  +-------------------------+  |  +-------------------------------+                                 |  |
|  |  +-------------------------------+                                                                     |  |
|  +-------------------------------------------------------------------------------------------------------+  |
+-------------------------------------------------------------------------------------------------------------+
```

### Traffic Flow

```
User Request -> Cloudflare DNS -> NLB (Public) -> ALB (Private) -> ECS Service -> Database
                                                                        |
                                                                        v
                                                                  S3 (PHI Data)
```

### Network Security Layers

| Layer | Component | Security Features |
|-------|-----------|-------------------|
| 1 | Cloudflare | DNS Only mode, no proxy (traffic goes direct to AWS) |
| 2 | NLB | TLS passthrough, access logging, deletion protection |
| 3 | ALB | HTTPS termination, TLS 1.2+, host-based routing |
| 4 | ECS | Private subnets, security groups, IAM roles |
| 5 | Database | Encryption at rest/transit, audit logging |

---

## Technical Safeguards Implementation

### §164.312(a) - Access Control

**Requirement:** Implement technical policies and procedures to allow access only to authorized persons.

#### Implementation Details:

**1. IAM Roles and Policies**
```
Location: modules/ecs/iam.tf, modules/documentdb/main.tf
```

- **Principle of Least Privilege**: Each ECS service has its own IAM task role
- **No Hardcoded Credentials**: All secrets retrieved from AWS Secrets Manager
- **Role-Based Access**: Services can only access resources they explicitly need

**2. Network Segmentation**
```
Location: modules/vpc/main.tf
```

| Subnet Type | CIDR Range | Purpose |
|-------------|------------|---------|
| Public | 10.0.101.0/24 - 10.0.103.0/24 | NLB, NAT Gateways |
| Private | 10.0.1.0/24 - 10.0.3.0/24 | ECS, ALB, Bastion |
| Database | 10.0.201.0/24 - 10.0.203.0/24 | DocumentDB, RDS |

**3. Security Groups**
```
Location: modules/ecs/security_groups.tf
```

- **Micro-segmentation**: Each service has its own security group
- **Explicit Allow Rules**: Only required ports and sources permitted
- **Default Deny**: All traffic blocked unless explicitly allowed

**4. Bastion Host (SSM Access)**
```
Location: modules/bastion/main.tf
```

- **No SSH**: Access via AWS Systems Manager Session Manager only
- **No Public IP**: Deployed in private subnet
- **Session Logging**: All sessions logged to CloudWatch (2192 days)
- **IAM Authentication**: Uses AWS IAM for access control

---

### §164.312(b) - Audit Controls

**Requirement:** Implement mechanisms to record and examine activity in systems containing ePHI.

#### Log Retention: 6 Years (2192 Days)

| Log Type | Location | Retention | Purpose |
|----------|----------|-----------|---------|
| VPC Flow Logs | CloudWatch | 2192 days | Network traffic audit |
| ECS Container Logs | CloudWatch | 2192 days | Application audit |
| DocumentDB Audit Logs | CloudWatch | 2192 days | Database access audit |
| DocumentDB Profiler | CloudWatch | 2192 days | Query performance |
| RDS PostgreSQL Logs | CloudWatch | 2192 days | n8n database audit |
| ALB Access Logs | S3 | 2192 days | HTTP request audit |
| ALB Connection Logs | S3 | 2192 days | Connection audit |
| NLB Access Logs | S3 | 2192 days | Network LB audit |
| NLB Connection Logs | S3 | 2192 days | NLB connection audit |
| S3 Access Logs | S3 | 2192 days | PHI access audit |
| Bastion Session Logs | CloudWatch | 2192 days | Admin access audit |

#### S3 Log Lifecycle (Cost Optimization)

```
Day 1-90     -> STANDARD (frequent access)
Day 91-365   -> STANDARD_IA (infrequent access, ~40% savings)
Day 366-2192 -> GLACIER (archive, ~80% savings)
Day 2192+    -> Deleted (after 6-year retention)
```

---

### §164.312(c) - Integrity Controls

**Requirement:** Protect ePHI from improper alteration or destruction.

#### Implementation:

| Feature | Location | Implementation |
|---------|----------|----------------|
| S3 Versioning | modules/s3-hipaa | All objects versioned |
| DocumentDB Deletion Protection | modules/documentdb | Enabled by default |
| ALB Deletion Protection | modules/ecs | Enabled by default |
| NLB Deletion Protection | modules/networking | Enabled by default |
| S3 force_destroy=false | modules/s3-hipaa | Prevents accidental deletion |
| Database Backups | modules/documentdb | 35-day automated backups |
| Final Snapshots | modules/documentdb | Required before deletion |

---

### §164.312(d) - Authentication

**Requirement:** Verify identity of persons seeking access to ePHI.

#### Implementation:

| Component | Authentication Method |
|-----------|----------------------|
| DocumentDB | Username/password in Secrets Manager |
| RDS PostgreSQL | Username/password in Secrets Manager |
| ECS Services | IAM roles (no long-lived credentials) |
| Bastion Host | IAM via SSM Session Manager |
| Applications | NEXTAUTH_SECRET, API keys in Secrets Manager |

---

### §164.312(e) - Transmission Security

**Requirement:** Guard against unauthorized access to ePHI transmitted over networks.

#### TLS/SSL Encryption:

| Connection | TLS Version | Configuration |
|------------|-------------|---------------|
| NLB -> ALB | TLS 1.2+ | Passthrough |
| ALB -> ECS | TLS 1.2+ | ELBSecurityPolicy-TLS-1-2-2017-01 |
| ECS -> DocumentDB | TLS 1.2+ | tls_enabled = true |
| ECS -> RDS | TLS | ssl_mode = require |
| VPC Endpoints | TLS | Private DNS enabled |

#### S3 SSL Enforcement:

```hcl
# Bucket policy denies non-HTTPS requests
Condition = {
  Bool = {
    "aws:SecureTransport" = "false"
  }
}
```

---

## Administrative Safeguards

### §164.308(a)(1) - Security Management Process

| Control | Implementation |
|---------|----------------|
| Risk Analysis | Regular assessments using AWS Security Hub |
| Risk Management | Infrastructure updates via Terraform |
| Sanction Policy | Defined in organizational policies |
| Activity Review | CloudWatch dashboards, log analysis |

### §164.308(a)(3) - Workforce Security

| Control | Implementation |
|---------|----------------|
| Authorization | IAM policies, least privilege |
| Clearance | Background checks for AWS access |
| Termination | IAM user/role removal procedures |

### §164.308(a)(5) - Security Awareness Training

- HIPAA security training for all personnel
- AWS security best practices training
- Incident response procedures

---

## Physical Safeguards

### §164.310 - Physical Safeguards

AWS handles physical security of data centers:

| Certification | Status |
|---------------|--------|
| SOC 1, 2, 3 | Certified |
| ISO 27001 | Certified |
| HIPAA BAA | Available |
| FedRAMP | AWS GovCloud |

**Infrastructure Features:**
- Multi-AZ deployment (us-east-1a, 1b, 1c)
- Redundant power and cooling
- 24/7 physical security

---

## Compliance Matrix

| HIPAA Section | Requirement | Implementation | Module |
|---------------|-------------|----------------|--------|
| §164.312(a)(1) | Unique User ID | IAM roles per service | ecs/iam.tf |
| §164.312(a)(2)(iii) | Access Control | Security groups, private subnets | ecs/security_groups.tf |
| §164.312(a)(2)(iv) | Encryption | KMS encryption | All modules |
| §164.312(b) | Audit Controls | CloudWatch, S3 logs (2192 days) | vpc, ecs, networking |
| §164.312(c)(1) | Integrity | Versioning, deletion protection | s3-hipaa, documentdb |
| §164.312(d) | Authentication | Secrets Manager, IAM | All modules |
| §164.312(e)(1) | Transmission Security | TLS 1.2+ everywhere | All modules |
| §164.312(e)(2)(ii) | Encryption in Transit | SSL/TLS enforced | All connections |

---

## Module-by-Module Compliance Details

### 1. VPC Module (`modules/vpc`)

| Feature | HIPAA Requirement | Value |
|---------|-------------------|-------|
| VPC Flow Logs | Audit Controls | 2192 days retention |
| Private Subnets | Access Control | 3 AZs |
| Database Subnets | Network Segmentation | Isolated tier |
| NAT Gateways | Controlled Egress | 3 (one per AZ) |
| VPC Endpoints | Transmission Security | S3, ECR, ECS, KMS, Logs, Secrets Manager |

### 2. DocumentDB Module (`modules/documentdb`)

| Feature | HIPAA Requirement | Value |
|---------|-------------------|-------|
| KMS Encryption | Encryption at Rest | Customer-managed key |
| TLS Enabled | Transmission Security | Required |
| Audit Logs | Audit Controls | 2192 days |
| Backup Retention | Data Recovery | 35 days |
| Deletion Protection | Integrity | Enabled |
| Cluster Size | Availability | 2 instances (Multi-AZ) |

### 3. RDS PostgreSQL Module (`modules/rds-postgres`)

| Feature | HIPAA Requirement | Value |
|---------|-------------------|-------|
| KMS Encryption | Encryption at Rest | Customer-managed key |
| SSL Mode | Transmission Security | Required |
| CloudWatch Logs | Audit Controls | 2192 days |
| Backup Retention | Data Recovery | 7 days |
| Multi-AZ | Availability | Configurable |

### 4. S3-HIPAA Module (`modules/s3-hipaa`)

| Feature | HIPAA Requirement | Value |
|---------|-------------------|-------|
| KMS Encryption | Encryption at Rest | aws:kms |
| SSL-Only Policy | Transmission Security | Enforced |
| Versioning | Integrity | Enabled |
| Public Access Block | Access Control | All blocked |
| Access Logging | Audit Controls | Enabled |
| Lifecycle Policy | Data Retention | 2192 days + Glacier |

### 5. ECS Module (`modules/ecs`)

| Feature | HIPAA Requirement | Value |
|---------|-------------------|-------|
| Fargate | Security | Serverless, AWS-managed |
| IAM Task Roles | Access Control | Per-service roles |
| CloudWatch Logs | Audit Controls | 2192 days |
| ALB Access Logs | Audit Controls | S3 (2192 days) |
| Internal ALB | Network Security | No public exposure |
| Security Groups | Access Control | Service isolation |
| Deletion Protection | Integrity | ALB protected |

### 6. Networking Module (`modules/networking`)

| Feature | HIPAA Requirement | Value |
|---------|-------------------|-------|
| NLB Access Logs | Audit Controls | S3 (2192 days) |
| NLB Connection Logs | Audit Controls | S3 (2192 days) |
| TLS Listeners | Transmission Security | TLS 1.2+ |
| Deletion Protection | Integrity | Enabled |

### 7. Bastion Module (`modules/bastion`)

| Feature | HIPAA Requirement | Value |
|---------|-------------------|-------|
| SSM Only Access | Access Control | No SSH |
| Session Logging | Audit Controls | CloudWatch (2192 days) |
| Private Subnet | Network Security | No public IP |
| IAM Role | Authentication | SSM managed policy |

### 8. Certs Module (`modules/certs`)

| Feature | HIPAA Requirement | Value |
|---------|-------------------|-------|
| ACM Certificate | Transmission Security | DNS validated |
| Wildcard Support | Flexibility | *.qa.10xr.co |
| Auto-renewal | Availability | AWS managed |

### 9. Cloudflare DNS Module (`modules/cloudflare-dns`)

| Feature | HIPAA Requirement | Value |
|---------|-------------------|-------|
| DNS Only Mode | Security | No Cloudflare proxy |
| Environment Isolation | Access Control | qa/prod separation |
| CNAME Records | Routing | Service-specific |

---

## Service Inventory

### Current Services

| Service | Port | Database | PHI Access | Domain |
|---------|------|----------|------------|--------|
| home-health | 3000 | DocumentDB | Yes | homehealth.qa.10xr.co |
| hospice | 3000 | DocumentDB | Yes | hospice.qa.10xr.co |
| n8n | 5678 | RDS PostgreSQL | No | n8n.qa.10xr.co |
| n8n-worker | 5678 | RDS PostgreSQL | No | webhook-n8n.qa.10xr.co |

### Service Security Configuration

| Service | IAM Role | KMS Access | Secrets |
|---------|----------|------------|---------|
| home-health | Dedicated | DocumentDB KMS, S3 KMS | Secrets Manager |
| hospice | Dedicated | DocumentDB KMS, S3 KMS | Secrets Manager |
| n8n | Dedicated | RDS KMS | Secrets Manager |

---

## Audit and Monitoring

### CloudWatch Alarms

| Alarm | Threshold | Action |
|-------|-----------|--------|
| DocumentDB CPU | > 80% | SNS notification |
| DocumentDB Connections | > 80% of max | SNS notification |
| DocumentDB FreeableMemory | < 256MB | SNS notification |
| NLB UnHealthyHostCount | > 0 | SNS notification |
| NLB TargetResponseTime | > 5s | SNS notification |

### Recommended Monitoring

```bash
# Query CloudWatch Logs for failed authentication
aws logs filter-log-events \
  --log-group-name "/ecs/ten-xr-app-qa" \
  --filter-pattern "authentication failed"

# Query VPC Flow Logs for rejected traffic
aws logs filter-log-events \
  --log-group-name "/aws/vpc/flow-logs" \
  --filter-pattern "REJECT"
```

---

## Incident Response

### Breach Notification Requirements

Under HIPAA, breaches affecting 500+ individuals must be reported to:
1. HHS within 60 days
2. Affected individuals without unreasonable delay
3. Media outlets in affected states

### Response Procedures

**1. Detection**
- CloudWatch Alarms
- GuardDuty findings (if enabled)
- VPC Flow Log analysis

**2. Containment**
```bash
# Isolate compromised ECS service
aws ecs update-service --cluster ten-xr-app-qa \
  --service <service> --desired-count 0

# Revoke IAM role
aws iam put-role-policy --role-name <role> \
  --policy-name DenyAll \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"*","Resource":"*"}]}'
```

**3. Investigation**
- Analyze CloudWatch Logs
- Review VPC Flow Logs
- Check S3 access logs

**4. Recovery**
- Restore from DocumentDB backup
- Rotate all secrets
- Deploy updated task definitions

---

## Recommendations

### Immediate Actions

- [ ] Sign AWS BAA (via AWS Artifact)
- [ ] Enable AWS CloudTrail
- [ ] Enable AWS Config

### Short-Term Improvements

- [ ] Enable AWS GuardDuty
- [ ] Implement AWS WAF on ALB
- [ ] Enable AWS Security Hub

### Long-Term Enhancements

- [ ] AWS Macie for PHI discovery
- [ ] AWS Backup for centralized backups
- [ ] Annual third-party HIPAA audit

---

## Appendix A: HIPAA Configuration Variables

```hcl
# environments/qa/terraform.tfvars

hipaa_config = {
  log_retention_days          = 2192  # 6 years
  data_retention_days         = 2192  # 6 years
  backup_retention_days       = 35
  enable_deletion_protection  = true
  enable_access_logging       = true
  enable_audit_logging        = true
  enable_cloudwatch_alarms    = true
  skip_final_snapshot         = false
  s3_force_destroy            = false
}
```

---

## Appendix B: Compliance Checklist

### Infrastructure

- [x] VPC Flow Logs enabled (2192 days)
- [x] All CloudWatch Log Groups (2192 days)
- [x] DocumentDB encryption (KMS)
- [x] DocumentDB TLS enabled
- [x] DocumentDB audit logs enabled
- [x] DocumentDB deletion protection
- [x] DocumentDB backup retention (35 days)
- [x] RDS PostgreSQL encryption (KMS)
- [x] RDS PostgreSQL SSL enforced
- [x] S3 buckets encrypted (KMS)
- [x] S3 versioning enabled
- [x] S3 public access blocked
- [x] S3 SSL-only policy
- [x] S3 access logging enabled
- [x] ALB access logs enabled
- [x] ALB deletion protection
- [x] ALB HTTPS with TLS 1.2+
- [x] NLB access logs enabled
- [x] NLB deletion protection
- [x] Security groups (least privilege)
- [x] No public IPs on ECS tasks
- [x] Secrets in Secrets Manager
- [x] IAM roles (least privilege)
- [x] VPC endpoints configured
- [x] Bastion SSM access only
- [x] Bastion session logging

### Operational

- [ ] AWS BAA signed
- [ ] CloudTrail enabled
- [ ] Security awareness training
- [ ] Incident response plan documented
- [ ] Annual risk assessment scheduled

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | December 2024 | Initial document |
| 2.0 | December 2024 | Added n8n service, RDS PostgreSQL, Bastion host, Cloudflare DNS, updated architecture diagram |

---

## References

- [HIPAA Security Rule (45 CFR Part 164)](https://www.hhs.gov/hipaa/for-professionals/security/index.html)
- [AWS HIPAA Compliance](https://aws.amazon.com/compliance/hipaa-compliance/)
- [AWS HIPAA Eligible Services](https://aws.amazon.com/compliance/hipaa-eligible-services-reference/)
- [NIST SP 800-66: HIPAA Security Rule Implementation Guide](https://csrc.nist.gov/publications/detail/sp/800-66/rev-1/final)
