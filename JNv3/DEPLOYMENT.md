# JobQuest Navigator v3 - Complete Deployment Guide

This guide explains how to deploy the complete JobQuest Navigator v3 application to AWS using GitHub Actions.

## 🚀 Overview

The deployment system uses GitHub Actions to automatically:

1. **Deploy AWS Infrastructure** - Terraform creates VPC, ECS, RDS, ALB, and all required AWS resources
2. **Build & Push Docker Images** - Creates production-ready containers for both frontend and backend
3. **Deploy ECS Services** - Updates task definitions and deploys services to ECS Fargate
4. **Validate Deployment** - Performs health checks and validates the deployment

## 📋 Prerequisites

### 1. AWS Account Setup
- AWS account with programmatic access
- IAM user with appropriate permissions (EC2, ECS, RDS, VPC, ALB, ECR, CloudWatch)
- AWS CLI configured (optional, for local testing)

### 2. GitHub Repository
- Repository with the JobQuest Navigator v3 code
- Admin access to configure secrets and workflows

### 3. Required Tools (for local development)
- Docker and Docker Buildx
- Terraform >= 1.6.0
- GitHub CLI (for secret management)
- Python 3.11+ (for utility scripts)

## 🔐 Step 1: Configure GitHub Secrets

### Required Secrets

Add these secrets to your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name | Description | How to Generate |
|-------------|-------------|-----------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | From AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | From AWS IAM Console |
| `SECRET_KEY` | Application Secret Key | Run: `python3 -c "import secrets; print(secrets.token_urlsafe(50))"` |
| `DB_PASSWORD` | Database Password | Run: `python3 JNv3/infrastructure/scripts/generate-db-password.py` |

### Optional Secrets

| Secret Name | Description |
|-------------|-------------|
| `OPENAI_API_KEY` | OpenAI API key for AI features |

### Quick Secret Generation

```bash
# Generate SECRET_KEY
python3 -c "import secrets; print(secrets.token_urlsafe(50))"

# Generate DB_PASSWORD
python3 JNv3/infrastructure/scripts/generate-db-password.py
```

## 🛠️ Step 2: Prepare Infrastructure

### Terraform Backend Configuration

Create the S3 backend configuration file:

```bash
# Create backend config
mkdir -p JNv3/infrastructure/terraform/backend-configs
cat > JNv3/infrastructure/terraform/backend-configs/production.hcl << 'EOF'
bucket         = "your-terraform-state-bucket"
key            = "jobquest-navigator-v3/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
EOF
```

> **Note:** You need to create the S3 bucket and DynamoDB table manually or use local state if this is a development deployment.

### Terraform Outputs Configuration

Ensure `outputs.tf` exists:

```bash
cat > JNv3/infrastructure/terraform/outputs.tf << 'EOF'
output "application_url" {
  description = "Application Load Balancer URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "backend_ecr_repository_url" {
  description = "Backend ECR repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_ecr_repository_url" {
  description = "Frontend ECR repository URL"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "database_username" {
  description = "Database username"
  value       = aws_db_instance.main.username
}
EOF
```

## ✅ Step 3: Pre-Deployment Check

Run the pre-deployment check to verify everything is configured:

```bash
./JNv3/infrastructure/scripts/pre-deployment-check.sh
```

This script will check:
- ✅ GitHub CLI authentication
- ✅ Required GitHub secrets
- ✅ Terraform configuration files
- ✅ Application Docker files

## 🚀 Step 4: Deploy

### Automatic Deployment (Recommended)

Push to the main branch to trigger automatic deployment:

```bash
git add .
git commit -m "Deploy JobQuest Navigator v3 complete application"
git push origin main
```

### Manual Deployment

Trigger deployment manually using GitHub CLI:

```bash
gh workflow run deploy-complete-app.yml
```

Or use the GitHub web interface:
1. Go to `Actions` tab in your repository
2. Select `Deploy Complete JobQuest Navigator v3 Application`
3. Click `Run workflow`
4. Select options:
   - Environment: `production`
   - Skip infrastructure: `false` (for first deployment)

## 📊 Step 5: Monitor Deployment

### GitHub Actions Dashboard

Monitor deployment progress in the GitHub Actions tab:

1. **Deploy AWS Infrastructure** - Creates/updates AWS resources (~5-10 minutes)
2. **Build and Push Docker Images** - Builds containers (~5-15 minutes)
3. **Deploy ECS Services** - Updates services (~5-10 minutes)
4. **Validate Deployment** - Health checks (~2-5 minutes)

### AWS Console Monitoring

Check deployment status in AWS Console:

- **ECS Console**: Service status and task health
- **CloudWatch Logs**: Application logs and errors
- **Application Load Balancer**: Target group health
- **RDS Console**: Database connectivity

## 🌐 Step 6: Access Your Application

After successful deployment, access your application:

- **Frontend**: `http://[ALB-DNS-NAME]/`
- **Backend API**: `http://[ALB-DNS-NAME]/api/health`
- **GraphQL**: `http://[ALB-DNS-NAME]/graphql`

The application URL will be displayed in the GitHub Actions summary.

## 🔧 Advanced Configuration

### Environment Variables

The deployment automatically configures these environment variables:

**Backend:**
- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY`: Application secret
- `ENVIRONMENT`: production
- `AWS_DEFAULT_REGION`: us-east-1
- `CORS_ORIGINS`: ALB DNS name
- `LOG_LEVEL`: info
- `DEBUG`: false
- `WORKERS`: 2

**Frontend:**
- `REACT_APP_API_URL`: Backend API URL
- `REACT_APP_GRAPHQL_URL`: GraphQL endpoint URL
- `NODE_ENV`: production
- `REACT_APP_ENV`: production

### Skipping Infrastructure Deployment

For subsequent deployments (when infrastructure already exists):

```bash
gh workflow run deploy-complete-app.yml -f skip_infrastructure=true
```

### Resource Scaling

Modify resource allocation in `JNv3/infrastructure/terraform/variables.tf`:

```hcl
variable "backend_cpu" {
  default = 512  # Increase for more CPU
}

variable "backend_memory" {
  default = 1024  # Increase for more memory
}
```

## 🛠️ Troubleshooting

### Common Issues

**1. Terraform Backend Not Found**
```bash
# Initialize backend manually
cd JNv3/infrastructure/terraform
terraform init -backend-config=backend-configs/production.hcl
```

**2. Docker Build Failures**
- Check Dockerfile syntax
- Verify all required files are present
- Check build logs in GitHub Actions

**3. ECS Service Health Check Failures**
- Check CloudWatch logs for application errors
- Verify database connectivity
- Check environment variable configuration

**4. Database Connection Issues**
- Verify `DB_PASSWORD` secret is correct
- Check RDS security group configuration
- Verify database endpoint connectivity

### Health Check Commands

```bash
# Check ECS services
aws ecs describe-services --cluster jobquest-navigator-v3-cluster --services jobquest-navigator-v3-backend-service

# Check task logs
aws logs tail /ecs/jobquest-navigator-v3/backend --follow

# Test endpoints
curl http://[ALB-DNS]/api/health
curl http://[ALB-DNS]/
```

### Rollback Procedure

If deployment fails, rollback manually:

```bash
# Get previous task definition revision
aws ecs describe-task-definition --task-definition jobquest-navigator-v3-backend

# Rollback services
aws ecs update-service --cluster jobquest-navigator-v3-cluster --service jobquest-navigator-v3-backend-service --task-definition jobquest-navigator-v3-backend:PREVIOUS_REVISION
aws ecs update-service --cluster jobquest-navigator-v3-cluster --service jobquest-navigator-v3-frontend-service --task-definition jobquest-navigator-v3-frontend:PREVIOUS_REVISION
```

## 🧹 Cleanup

To completely remove the deployment:

```bash
cd JNv3/infrastructure/terraform
terraform destroy -auto-approve \
  -var="project_name=jobquest-navigator-v3" \
  -var="aws_region=us-east-1" \
  -var="secret_key=dummy"
```

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Multi-platform Builds](https://docs.docker.com/build/building/multi-platform/)

## 🆘 Support

If you encounter issues:

1. Check the GitHub Actions logs for detailed error messages
2. Review AWS CloudWatch logs for application-specific errors
3. Verify all prerequisites are met
4. Check the troubleshooting section above

---

**Happy Deploying! 🚀**