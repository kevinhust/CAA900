# Terraform Backend Configuration for JobQuest Navigator v2
# S3 backend with DynamoDB state locking

terraform {
  backend "s3" {
    bucket         = "caa900resume"
    key            = "jobquest-navigator-v3/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    
    # DynamoDB table for state locking
    dynamodb_table = "terraform-state-locks"
    
    # Workspace-specific state files
    workspace_key_prefix = "environments"
  }
}

# Backend configuration files for different environments
# Use with: terraform init -backend-config=backend-configs/development.hcl