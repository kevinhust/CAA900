#!/bin/bash

# JobQuest Navigator v3 - Complete AWS Deployment Script
# This script deploys the complete infrastructure to AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-development}
TERRAFORM_DIR="/Users/kevinwang/Documents/Projects/CAA900/JNv3/infrastructure/terraform"
TFVARS_FILE="environments/${ENVIRONMENT}.tfvars"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform and try again."
        exit 1
    fi
    
    # Check if AWS CLI is installed and configured
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI and try again."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' and try again."
        exit 1
    fi
    
    # Check if tfvars file exists
    if [[ ! -f "$TFVARS_FILE" ]]; then
        print_error "Environment file $TFVARS_FILE not found."
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Function to initialize terraform
init_terraform() {
    print_header "Initializing Terraform"
    
    cd "$TERRAFORM_DIR"
    
    # Initialize terraform
    terraform init
    
    print_status "Terraform initialized successfully"
}

# Function to clean up problematic resources
cleanup_resources() {
    print_header "Cleaning Up Problematic Resources"
    
    print_warning "Removing deposed security group resources..."
    
    # Remove deposed objects that might cause conflicts
    terraform state list | grep "deposed" | while read resource; do
        print_warning "Removing deposed resource: $resource"
        terraform state rm "$resource" || true
    done
    
    print_status "Cleanup completed"
}

# Function to create ECR repositories and push images
setup_ecr() {
    print_header "Setting Up ECR Repositories"
    
    # Get AWS account ID and region
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)
    
    print_status "AWS Account ID: $AWS_ACCOUNT_ID"
    print_status "AWS Region: $AWS_REGION"
    
    # Create ECR repositories if they don't exist
    BACKEND_REPO="jobquest-nav-${ENVIRONMENT}-jobquest-backend"
    FRONTEND_REPO="jobquest-nav-${ENVIRONMENT}-jobquest-frontend"
    
    # Create backend repository
    if ! aws ecr describe-repositories --repository-names "$BACKEND_REPO" &> /dev/null; then
        print_status "Creating ECR repository: $BACKEND_REPO"
        aws ecr create-repository --repository-name "$BACKEND_REPO" --region "$AWS_REGION"
    fi
    
    # Create frontend repository  
    if ! aws ecr describe-repositories --repository-names "$FRONTEND_REPO" &> /dev/null; then
        print_status "Creating ECR repository: $FRONTEND_REPO"
        aws ecr create-repository --repository-name "$FRONTEND_REPO" --region "$AWS_REGION"
    fi
    
    # Push placeholder images
    print_status "Pushing placeholder images to ECR..."
    
    # Login to ECR
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    
    # Create and push backend placeholder
    docker pull python:3.11-slim
    docker tag python:3.11-slim "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:latest"
    docker push "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:latest"
    
    # Create and push frontend placeholder
    docker pull node:18-alpine
    docker tag node:18-alpine "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:latest"
    docker push "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:latest"
    
    print_status "ECR setup completed"
}

# Function to plan terraform deployment
plan_deployment() {
    print_header "Planning Terraform Deployment"
    
    cd "$TERRAFORM_DIR"
    
    # Run terraform plan
    terraform plan -var-file="$TFVARS_FILE" -out="deployment-plan"
    
    print_status "Terraform plan completed"
    
    # Ask for confirmation
    echo
    read -p "Do you want to apply this plan? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled by user"
        exit 0
    fi
}

# Function to apply terraform deployment
apply_deployment() {
    print_header "Applying Terraform Deployment"
    
    cd "$TERRAFORM_DIR"
    
    # Apply the plan
    terraform apply "deployment-plan"
    
    print_status "Terraform deployment completed successfully"
}

# Function to show deployment outputs
show_outputs() {
    print_header "Deployment Outputs"
    
    cd "$TERRAFORM_DIR"
    
    # Show terraform outputs
    terraform output
    
    print_status "Deployment information displayed above"
}

# Function to validate deployment
validate_deployment() {
    print_header "Validating Deployment"
    
    cd "$TERRAFORM_DIR"
    
    # Get outputs
    ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "Not available")
    RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "Not available")
    
    print_status "ALB DNS Name: $ALB_DNS"
    print_status "RDS Endpoint: $RDS_ENDPOINT"
    
    if [[ "$ALB_DNS" != "Not available" ]]; then
        print_status "✅ Load Balancer deployed successfully"
    else
        print_warning "⚠️  Load Balancer information not available"
    fi
    
    if [[ "$RDS_ENDPOINT" != "Not available" ]]; then
        print_status "✅ RDS Database deployed successfully"
    else
        print_warning "⚠️  RDS Database information not available"
    fi
    
    print_status "Validation completed"
}

# Main deployment function
main() {
    print_header "JobQuest Navigator v3 - AWS Deployment"
    print_status "Environment: $ENVIRONMENT"
    print_status "Terraform Directory: $TERRAFORM_DIR"
    print_status "Variables File: $TFVARS_FILE"
    
    echo
    
    # Run deployment steps
    check_prerequisites
    init_terraform
    cleanup_resources
    setup_ecr
    plan_deployment
    apply_deployment
    show_outputs
    validate_deployment
    
    print_header "Deployment Completed Successfully!"
    print_status "Your JobQuest Navigator v3 infrastructure is now deployed to AWS"
    print_status "Environment: $ENVIRONMENT"
    
    echo
    print_status "Next steps:"
    print_status "1. Build and push your application images to ECR"
    print_status "2. Update ECS services to use your application images"
    print_status "3. Configure your DNS and SSL certificates"
    print_status "4. Run application database migrations"
}

# Run main function
main "$@"