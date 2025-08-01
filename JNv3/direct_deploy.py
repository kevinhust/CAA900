#!/usr/bin/env python3
"""
Direct deployment script - Build and deploy Docker images without Terraform
"""
import boto3
import subprocess
import sys
import json
import time

def run_command(command, description=""):
    """Run shell command and return result"""
    print(f"🔧 {description if description else command}")
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
        if result.stdout:
            print(result.stdout)
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        print(f"❌ Command failed: {e}")
        if e.stderr:
            print(f"Error: {e.stderr}")
        return False, e.stderr

def get_aws_account_id():
    """Get AWS account ID"""
    try:
        sts_client = boto3.client('sts')
        return sts_client.get_caller_identity()['Account']
    except Exception as e:
        print(f"❌ Failed to get AWS account ID: {e}")
        return None

def build_and_push_images():
    """Build and push Docker images to ECR with AMD64 architecture"""
    account_id = get_aws_account_id()
    if not account_id:
        return False
    
    region = 'us-east-1'
    backend_repo = f"{account_id}.dkr.ecr.{region}.amazonaws.com/jobquest-navigator-v3-backend"
    frontend_repo = f"{account_id}.dkr.ecr.{region}.amazonaws.com/jobquest-navigator-v3-frontend"
    
    print("🚀 Starting Docker build and push process...")
    print("⚠️  NOTE: Building AMD64 images on M1 Mac for ECS Fargate compatibility")
    
    # Setup Docker Buildx for cross-platform builds
    success, _ = run_command(
        "docker buildx create --name amd64-builder --use --bootstrap || docker buildx use amd64-builder",
        "Setup Docker Buildx for AMD64 builds"
    )
    if not success:
        return False
    
    # ECR login
    success, _ = run_command(
        f"aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {account_id}.dkr.ecr.{region}.amazonaws.com",
        "ECR Docker login"
    )
    if not success:
        return False
    
    # Build and push backend with explicit AMD64 platform
    print("\n📦 Building backend image for AMD64...")
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    success, _ = run_command(
        f"cd apps/backend-fastapi && docker buildx build "
        f"--platform linux/amd64 "
        f"--tag {backend_repo}:latest "
        f"--tag {backend_repo}:{timestamp} "
        f"--push .",
        "Build and push backend image (AMD64)"
    )
    if not success:
        print("❌ Backend image build failed")
        return False
    
    # Build and push frontend with explicit AMD64 platform
    print("\n📦 Building frontend image for AMD64...")
    success, _ = run_command(
        f"cd apps/frontend-react && docker buildx build "
        f"--platform linux/amd64 "
        f"--tag {frontend_repo}:latest "
        f"--tag {frontend_repo}:{timestamp} "
        f"--push .",
        "Build and push frontend image (AMD64)"
    )
    if not success:
        print("❌ Frontend image build failed")
        return False
    
    print("✅ Both images built and pushed successfully with AMD64 architecture")
    return True

def update_ecs_services():
    """Update ECS services to use latest images"""
    ecs_client = boto3.client('ecs', region_name='us-east-1')
    cluster_name = 'jobquest-navigator-v3-cluster'
    
    print("\n🔄 Updating ECS services...")
    
    services = [
        'jobquest-navigator-v3-backend-service',
        'jobquest-navigator-v3-frontend-service'
    ]
    
    for service_name in services:
        try:
            print(f"🔄 Updating service: {service_name}")
            response = ecs_client.update_service(
                cluster=cluster_name,
                service=service_name,
                forceNewDeployment=True
            )
            print(f"✅ Service {service_name} update initiated")
        except Exception as e:
            print(f"❌ Failed to update service {service_name}: {e}")
            return False
    
    return True

def wait_for_deployments():
    """Wait for ECS deployments to complete"""
    ecs_client = boto3.client('ecs', region_name='us-east-1')
    cluster_name = 'jobquest-navigator-v3-cluster'
    
    services = [
        'jobquest-navigator-v3-backend-service',
        'jobquest-navigator-v3-frontend-service'
    ]
    
    print("\n⏳ Waiting for deployments to complete...")
    
    for service_name in services:
        print(f"⏳ Monitoring {service_name}...")
        waiter = ecs_client.get_waiter('services_stable')
        try:
            waiter.wait(
                cluster=cluster_name,
                services=[service_name],
                WaiterConfig={
                    'Delay': 15,
                    'MaxAttempts': 40  # Wait up to 10 minutes
                }
            )
            print(f"✅ {service_name} deployment completed")
        except Exception as e:
            print(f"⚠️  {service_name} deployment timeout: {e}")
    
    return True

def check_application_health():
    """Check application health endpoints"""
    dns_name = "jobquest-navigator-v3-alb-1532571588.us-east-1.elb.amazonaws.com"
    
    endpoints = [
        ("Frontend", f"http://{dns_name}/"),
        ("Backend Health", f"http://{dns_name}/api/health"),
        ("GraphQL", f"http://{dns_name}/graphql")
    ]
    
    print("\n🏥 Checking application health...")
    
    for name, url in endpoints:
        try:
            success, output = run_command(
                f"curl -s -o /dev/null -w '%{{http_code}}' {url}",
                f"Testing {name}"
            )
            if success and output.strip() in ['200', '301', '302']:
                print(f"✅ {name}: HTTP {output.strip()}")
            else:
                print(f"⚠️  {name}: HTTP {output.strip()}")
        except Exception as e:
            print(f"❌ {name}: Failed - {e}")

def main():
    """Main deployment process"""
    print("🚀 JobQuest Navigator v3 - Direct Deployment")
    print("=" * 50)
    
    # Step 1: Build and push Docker images
    if not build_and_push_images():
        print("❌ Docker build and push failed")
        sys.exit(1)
    
    # Step 2: Update ECS services
    if not update_ecs_services():
        print("❌ ECS service update failed")
        sys.exit(1)
    
    # Step 3: Wait for deployments
    wait_for_deployments()
    
    # Step 4: Check application health
    check_application_health()
    
    print("\n✅ Deployment completed!")
    print(f"🌐 Application URL: http://jobquest-navigator-v3-alb-1532571588.us-east-1.elb.amazonaws.com")

if __name__ == "__main__":
    main()