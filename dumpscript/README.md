# Dumpscript Helm Chart

A Helm Chart for automating PostgreSQL and MySQL database backups on Kubernetes, with automatic upload to Amazon S3.

## Description

**Dumpscript** is a complete solution for automated database backups in Kubernetes environments. It creates independent CronJobs for each configured database, performing regular dumps and uploading them to AWS S3 buckets.

## Features

- ✅ **Multiple databases**: Support for PostgreSQL and MySQL
- ✅ **Database version support**: Configurable client versions for compatibility
- ✅ **Multiple backup schedules**: Support for daily, weekly, monthly, and yearly backups per database
- ✅ **Independent jobs**: Each database runs in a separate CronJob
- ✅ **S3 storage**: Automatic upload to Amazon S3
- ✅ **Flexible authentication**: Support for Kubernetes secrets or direct values
- ✅ **Custom scheduling**: Individual cron expressions per backup type
- ✅ **Custom arguments**: Database-specific dump options
- ✅ **AWS IAM Roles**: Support for roles for authentication
- ✅ **Security**: Credentials protected via Kubernetes Secrets
- ✅ **Slack notifications**: Optional notifications for backup status

## Installation

### Prerequisites

- Kubernetes 1.16+
- Helm 3.0+
- Access to AWS S3 buckets

### Install the Chart

```bash
# Add the repository (if applicable)
helm repo add cloudscript https://charts.cloudscript.technology
helm repo update

# Install the chart
helm install dumpscript cloudscript/dumpscript -f values.yaml
```

## Configuration

### Example values.yaml

```yaml
# Image configuration
image:
  repository: ghcr.io/cloudscript-technology/dumpscript
  pullPolicy: IfNotPresent
  tag: "latest"

# Database configuration
databases:
  # PostgreSQL with direct credentials
  - type: postgresql
    version: "17"  # PostgreSQL client version
    periodicity:
      - type: daily
        retentionDays: 7
        schedule: "0 2 * * *"  # Every day at 2:00 AM
      - type: weekly
        retentionDays: 30
        schedule: "0 3 * * 0"  # Every Sunday at 3:00 AM
      - type: monthly
        retentionDays: 365
        schedule: "0 4 1 * *"  # First day of month at 4:00 AM
    connectionInfo:
      host: "postgres.example.com"
      username: "backup_user"
      password: "secret_password"
      database: "app_db"
      port: 5432
    aws:
      region: "us-west-2"
      bucket: "my-company-backups"
      bucketPrefix: "postgres-dumps/"
    extraArgs: "--verbose --single-transaction"

  # MySQL with secrets
  - type: mysql
    version: "10.11"  # MariaDB client version
    periodicity:
      - type: daily
        retentionDays: 7
        schedule: "0 1 * * *"  # Every day at 1:00 AM
      - type: weekly
        retentionDays: 30
        schedule: "0 2 * * 0"  # Every Sunday at 2:00 AM
    connectionInfo:
      secretName: "mysql-credentials"
    aws:
      secretName: "aws-credentials"
    extraArgs: "--opt --single-transaction"

# Slack notifications
notifications:
  slack:
    enabled: true
    webhookUrl: "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
    channel: "#backups"
    username: "Dumpscript Bot"
    notifyOnSuccess: false

# Service Account configuration
serviceAccount:
  create: true
  automount: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/BackupRole"
  name: ""
  namespace: ""

# Pod configuration
podAnnotations: {}
podLabels: {}

# Security context
podSecurityContext: {}
securityContext: {}

# Pod resources and configuration
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Network and scheduling configuration
nodeSelector: {}
tolerations: []
affinity: {}
```

## Database Version Support

### PostgreSQL Versions
- **13**: PostgreSQL 13.x
- **14**: PostgreSQL 14.x
- **15**: PostgreSQL 15.x
- **16**: PostgreSQL 16.x
- **17**: PostgreSQL 17.x (default)

### MySQL/MariaDB Versions
- **8.0**: MySQL 8.0
- **10.11**: MariaDB 10.11 (default)
- **11.4**: MariaDB 11.4

**Important**: The client version should match your database server version to avoid compatibility issues.

## Multiple Backup Schedules

Each database can have multiple backup schedules with different retention policies:

```yaml
databases:
  - type: postgresql
    version: "17"
    periodicity:
      - type: daily
        retentionDays: 7
        schedule: "0 2 * * *"  # Daily at 2:00 AM
      - type: weekly
        retentionDays: 30
        schedule: "0 3 * * 0"  # Weekly on Sunday at 3:00 AM
      - type: monthly
        retentionDays: 365
        schedule: "0 4 1 * *"  # Monthly on 1st at 4:00 AM
      - type: yearly
        retentionDays: 2555  # 7 years
        schedule: "0 5 1 1 *"  # Yearly on January 1st at 5:00 AM
```

## Kubernetes Secrets

### Secret for Database Credentials

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-credentials
  namespace: default
type: Opaque
data:
  host: bXlzcWwuZXhhbXBsZS5jb20=              # mysql.example.com
  username: YmFja3VwX3VzZXI=                  # backup_user
  password: c3VwZXJfc2VjcmV0X3Bhc3N3b3Jk        # super_secret_password
  database: YXBwX2Ri                          # app_db
  port: MzMwNg==                              # 3306
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
  namespace: default
type: Opaque
data:
  host: cG9zdGdyZXMuZXhhbXBsZS5jb20=          # postgres.example.com
  username: YmFja3VwX3VzZXI=                  # backup_user
  password: c3VwZXJfc2VjcmV0X3Bhc3N3b3Jk        # super_secret_password
  database: YXBwX2Ri                          # app_db
  port: NTQzMg==                              # 5432
```

### Secret for AWS Credentials

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: default
type: Opaque
data:
  region: dXMtd2VzdC0y                        # us-west-2
  bucket: bXktY29tcGFueS1iYWNrdXBz            # my-company-backups
  bucketPrefix: ZGF0YWJhc2UtZHVtcHMv            # database-dumps/
  # Optional: direct credentials (not recommended)
  # accessKeyId: QUtJQUlPU0ZPRE5ON0VYQU1QTEU=
  # secretAccessKey: d0phbExyWGVOdC9LN21ESVkvYk1FeFJZSEs0WUs1TUVRc1pKVHU=
```

### Secret for Production with AWS Role

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: production-aws-credentials
  namespace: default
type: Opaque
data:
  region: dXMtZWFzdC0x                        # us-east-1
  bucket: cHJvZHVjdGlvbi1kYi1iYWNrdXBz        # production-db-backups
  bucketPrefix: cG9zdGdyZXMtcHJvZC8=          # postgres-prod/
```

## Creating Secrets via kubectl

```bash
# Secret for MySQL database
kubectl create secret generic mysql-credentials \
  --from-literal=host=mysql.example.com \
  --from-literal=username=backup_user \
  --from-literal=password=super_secret_password \
  --from-literal=database=app_db \
  --from-literal=port=3306

# Secret for PostgreSQL database
kubectl create secret generic postgres-credentials \
  --from-literal=host=postgres.example.com \
  --from-literal=username=backup_user \
  --from-literal=password=super_secret_password \
  --from-literal=database=app_db \
  --from-literal=port=5432

# Secret for AWS (using IAM Role)
kubectl create secret generic aws-credentials \
  --from-literal=region=us-west-2 \
  --from-literal=bucket=my-company-backups \
  --from-literal=bucketPrefix=database-dumps/

# Secret for AWS (using Access Keys - not recommended)
kubectl create secret generic aws-credentials-keys \
  --from-literal=region=us-west-2 \
  --from-literal=bucket=my-company-backups \
  --from-literal=bucketPrefix=database-dumps/ \
  --from-literal=accessKeyId=AKIAIOSFODNN7EXAMPLE \
  --from-literal=secretAccessKey=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

## Configuration Parameters

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Docker image repository | `ghcr.io/cloudscript-technology/dumpscript` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.tag` | Image tag | `""` (uses appVersion) |
| `imagePullSecrets` | Image pull secrets | `[]` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full chart name | `""` |

### Database Configuration

| Parameter | Description | Required |
|-----------|-------------|----------|
| `databases[].type` | Database type (`postgresql` or `mysql`) | ✅ |
| `databases[].version` | Database client version | ✅ |
| `databases[].periodicity[].type` | Backup type (`daily`, `weekly`, `monthly`, `yearly`) | ✅ |
| `databases[].periodicity[].schedule` | Cron expression for scheduling | ✅ |
| `databases[].periodicity[].retentionDays` | Retention period in days (integer) | ✅ |
| `databases[].connectionInfo.host` | Database host | ✅* |
| `databases[].connectionInfo.username` | Database username | ✅* |
| `databases[].connectionInfo.password` | Database password | ✅* |
| `databases[].connectionInfo.database` | Database name | ✅* |
| `databases[].connectionInfo.port` | Database port | ✅* |
| `databases[].connectionInfo.secretName` | Secret name with credentials | ✅** |
| `databases[].aws.region` | AWS region | ✅* |
| `databases[].aws.bucket` | S3 bucket | ✅* |
| `databases[].aws.bucketPrefix` | Bucket prefix | ❌ |
| `databases[].aws.secretName` | AWS secret name | ✅** |
| `databases[].extraArgs` | Extra arguments for dump | ❌ |

*\* Required when `secretName` is not provided*  
*\*\* Required when direct values are not provided*

### Slack Notifications

| Parameter | Description | Default |
|-----------|-------------|---------|
| `notifications.slack.enabled` | Enable Slack notifications | `false` |
| `notifications.slack.webhookUrl` | Slack webhook URL | `""` |
| `notifications.slack.channel` | Slack channel (optional) | `""` |
| `notifications.slack.username` | Slack username (optional) | `""` |
| `notifications.slack.notifyOnSuccess` | Notify on successful backups | `false` |

### Service Account Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.automount` | Automount token | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |
| `serviceAccount.namespace` | Service account namespace | `""` |

### Pod Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podAnnotations` | Pod annotations | `{}` |
| `podLabels` | Pod labels | `{}` |
| `podSecurityContext` | Pod security context | `{}` |
| `securityContext` | Container security context | `{}` |
| `resources` | Resource requests and limits | `{}` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations | `[]` |
| `affinity` | Affinity rules | `{}` |

## Usage Examples

### Simple PostgreSQL Backup with Multiple Schedules

```yaml
databases:
  - type: postgresql
    version: "17"
    periodicity:
      - type: daily
        retentionDays: 7
        schedule: "0 2 * * *"  # Daily at 2:00 AM
      - type: weekly
        retentionDays: 30
        schedule: "0 3 * * 0"  # Weekly on Sunday at 3:00 AM
    connectionInfo:
      host: "postgres.internal"
      username: "backup_user"
      password: "backup_password"
      database: "myapp"
      port: 5432
    aws:
      region: "us-west-2"
      bucket: "myapp-backups"
      bucketPrefix: "postgres/"
    extraArgs: "--verbose --single-transaction"
```

### Backup with AWS IAM Role and Slack Notifications

```yaml
databases:
  - type: postgresql
    version: "16"
    periodicity:
      - type: daily
        retentionDays: 14
        schedule: "0 1 * * *"  # Daily at 1:00 AM
      - type: monthly
        retentionDays: 365
        schedule: "0 4 1 * *"  # Monthly on 1st at 4:00 AM
    connectionInfo:
      secretName: "db-credentials"
    aws:
      region: "us-west-2"
      bucket: "secure-backups"
      bucketPrefix: "production/postgres/"
    extraArgs: "--verbose --single-transaction"

notifications:
  slack:
    enabled: true
    webhookUrl: "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
    channel: "#backups"
    username: "Dumpscript Bot"
    notifyOnSuccess: false

serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/DatabaseBackupRole"
```

### Multiple Databases with Different Versions

```yaml
databases:
  # Production PostgreSQL
  - type: postgresql
    version: "17"
    periodicity:
      - type: daily
        retentionDays: 30
        schedule: "0 1 * * *"  # Daily at 1:00 AM
      - type: monthly
        retentionDays: 365
        schedule: "0 4 1 * *"  # Monthly on 1st at 4:00 AM
    connectionInfo:
      secretName: "prod-postgres-creds"
    aws:
      secretName: "prod-aws-creds"
      region: "us-west-2"
      bucket: "secure-backups"
      bucketPrefix: "production/postgres/"
    extraArgs: "--verbose --single-transaction"

  # Development MySQL
  - type: mysql
    version: "10.11"
    periodicity:
      - type: daily
        retentionDays: 14
        schedule: "0 2 * * *"  # Daily at 2:00 AM
      - type: weekly
        retentionDays: 60
        schedule: "0 3 * * 0"  # Weekly on Sunday at 3:00 AM
    connectionInfo:
      secretName: "dev-mysql-creds"
    aws:
      secretName: "dev-aws-creds"
      region: "us-west-2"
      bucket: "secure-backups"
      bucketPrefix: "develop/mysql/"
    extraArgs: "--opt --single-transaction"

  # Test PostgreSQL
  - type: postgresql
    version: "15"
    periodicity:
      - type: weekly
        retentionDays: 90
        schedule: "0 0 * * 0"  # Weekly on Sunday at midnight
    connectionInfo:
      secretName: "test-postgres-creds"
    aws:
      secretName: "test-aws-creds"
      region: "us-west-2"
      bucket: "secure-backups"
      bucketPrefix: "test/postgres/"
    extraArgs: "--clean --if-exists"
```

## Common Cron Expressions

| Expression | Description |
|------------|-------------|
| `0 2 * * *` | Every day at 2:00 AM |
| `0 */6 * * *` | Every 6 hours |
| `0 1 * * 0` | Every Sunday at 1:00 AM |
| `0 3 1 * *` | First day of month at 3:00 AM |
| `0 2 * * 1-5` | Monday to Friday at 2:00 AM |
| `0 5 1 1 *` | January 1st at 5:00 AM (yearly) |

## Common Extra Arguments

### PostgreSQL (`pg_dump`)

```bash
--verbose                    # Verbose output
--single-transaction         # Dump in a single transaction
--clean                      # Include DROP commands
--if-exists                  # Use IF EXISTS with DROP
--no-owner                   # Don't include owner commands
--no-privileges              # Don't include privilege commands
--encoding=UTF8              # Specify encoding
--schema=public              # Dump only public schema
```

### MySQL (`mysqldump`)

```bash
--opt                        # Default optimizations
--single-transaction         # Dump in a single transaction
--routines                   # Include stored procedures
--triggers                   # Include triggers
--events                     # Include events
--flush-logs                 # Flush logs before dump
--master-data=2              # Include replication information
--no-tablespaces             # Don't include tablespaces
```

## Troubleshooting

### Check CronJob Status

```bash
# List all cronjobs
kubectl get cronjobs

# Check specific jobs
kubectl get cronjobs -l app.kubernetes.io/name=dumpscript

# Check logs from a specific job
kubectl logs -l app.kubernetes.io/name=dumpscript,dumpscript.io/database-index=0
```

### Common Issues

**1. Database connection error**
```bash
# Check if secret exists
kubectl get secret mysql-credentials -o yaml

# Test connectivity
kubectl run debug --image=postgres:13 --rm -it -- psql -h postgres.example.com -U backup_user -d app_db
```

**2. AWS authentication error**
```bash
# Check if service account has correct annotations
kubectl get serviceaccount dumpscript -o yaml

# Check if IAM role exists and has correct permissions
aws iam get-role --role-name BackupRole
```

**3. S3 permissions error**
```bash
# Check bucket permissions
aws s3 ls s3://my-company-backups/database-dumps/

# Test manual upload
aws s3 cp test.txt s3://my-company-backups/database-dumps/
```

**4. Version compatibility issues**
```bash
# Check database server version
kubectl run debug --image=postgres:17 --rm -it -- psql -h postgres.example.com -U backup_user -d app_db -c "SELECT version();"

# Verify client version matches server version
```

### Detailed Logs

```bash
# Logs from a specific job
kubectl logs job/dumpscript-db-0-1234567890

# Logs from all jobs
kubectl logs -l app.kubernetes.io/name=dumpscript

# Follow logs in real-time
kubectl logs -f -l app.kubernetes.io/name=dumpscript
```

## Security

### Best Practices

1. **Use Kubernetes Secrets** for sensitive credentials
2. **Use IAM Roles** instead of access keys when possible
3. **Restrict permissions** to minimum required
4. **Use namespaces** for isolation
5. **Configure Network Policies** for traffic control
6. **Monitor logs** for suspicious activities
7. **Match client versions** with database server versions

## AWS IAM Policy Requirements

To allow Dumpscript to upload, list, and delete backups in your S3 bucket, the IAM role used by the container must have the following permissions:

- `s3:GetObject` – Read backup files from S3 (for restore)
- `s3:PutObject` – Upload new backup files to S3
- `s3:DeleteObject` – Remove old backups from S3 (for retention policy)
- `s3:ListBucket` – List objects in the S3 bucket (for cleanup and restore)
- `s3:ListObjects`, `s3:ListObjectsV2` – List objects within a bucket and support recursive listing (required for AWS CLI and scripts that use `aws s3 ls --recursive`)

Below is an example of a minimal IAM policy for S3 access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListObjects",
        "s3:ListObjectsV2"
      ],
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::your-bucket-name"
    }
  ]
}
```

Replace `your-bucket-name` with the actual name of your S3 bucket. Granting only these permissions ensures the tool can perform all backup, restore, and cleanup operations securely.

Generate new digest:
```bash
shasum -a 256 dumpscript-<version>.tgz
```