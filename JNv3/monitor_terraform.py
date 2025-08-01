#!/usr/bin/env python3
"""
Monitor Terraform deployment progress and infrastructure status
"""
import boto3
import time
import subprocess
import sys

def check_terraform_process():
    """Check if Terraform process is still running"""
    try:
        result = subprocess.run(['pgrep', '-f', 'terraform'], 
                              capture_output=True, text=True)
        return len(result.stdout.strip()) > 0
    except:
        return False

def check_infrastructure_status():
    """Check the status of key infrastructure components"""
    ec2_client = boto3.client('ec2', region_name='us-east-1')
    ecs_client = boto3.client('ecs', region_name='us-east-1')
    elb_client = boto3.client('elbv2', region_name='us-east-1')
    
    print("🔍 Checking infrastructure status...")
    
    # Check subnets
    try:
        subnets = ec2_client.describe_subnets(
            Filters=[
                {'Name': 'tag:Name', 'Values': ['jobquest-navigator-v3-*']}
            ]
        )
        print(f"📊 Subnets: {len(subnets['Subnets'])} found")
        for subnet in subnets['Subnets']:
            name = next((tag['Value'] for tag in subnet.get('Tags', []) 
                        if tag['Key'] == 'Name'), 'Unknown')
            print(f"  - {name}: {subnet['SubnetId']} ({subnet['State']})")
    except Exception as e:
        print(f"❌ Subnet check failed: {e}")
    
    # Check ECS services
    try:
        cluster_name = 'jobquest-navigator-v3-cluster'
        services = ecs_client.list_services(cluster=cluster_name)
        print(f"📊 ECS Services: {len(services['serviceArns'])} found")
        
        if services['serviceArns']:
            service_details = ecs_client.describe_services(
                cluster=cluster_name,
                services=services['serviceArns']
            )
            for service in service_details['services']:
                print(f"  - {service['serviceName']}: {service['status']} "
                      f"(desired: {service['desiredCount']}, running: {service['runningCount']})")
    except Exception as e:
        print(f"❌ ECS check failed: {e}")
    
    # Check load balancer
    try:
        lbs = elb_client.describe_load_balancers(
            Names=['jobquest-navigator-v3-alb']
        )
        if lbs['LoadBalancers']:
            lb = lbs['LoadBalancers'][0]
            print(f"📊 Load Balancer: {lb['State']['Code']}")
            print(f"  - DNS: {lb['DNSName']}")
    except Exception as e:
        print(f"❌ Load balancer check failed: {e}")

def main():
    """Main monitoring loop"""
    print("🚀 Starting infrastructure monitoring...")
    
    terraform_running = check_terraform_process()
    if terraform_running:
        print("⏳ Terraform is still running, waiting for completion...")
    
    while terraform_running:
        time.sleep(15)
        terraform_running = check_terraform_process()
        if terraform_running:
            print("⏳ Terraform still in progress...")
    
    print("✅ Terraform process completed!")
    
    # Wait a bit for resources to stabilize
    time.sleep(10)
    
    # Check infrastructure status
    check_infrastructure_status()
    
    # Test application endpoints
    print("\n🌐 Testing application endpoints...")
    dns_name = "jobquest-navigator-v3-alb-1532571588.us-east-1.elb.amazonaws.com"
    
    endpoints = [
        ("Frontend", f"http://{dns_name}/"),
        ("Backend API", f"http://{dns_name}/api/health"),
        ("GraphQL", f"http://{dns_name}/graphql")
    ]
    
    for name, url in endpoints:
        try:
            import urllib.request
            req = urllib.request.Request(url)
            req.add_header('User-Agent', 'Mozilla/5.0')
            
            with urllib.request.urlopen(req, timeout=10) as response:
                status = response.getcode()
                print(f"  - {name}: HTTP {status} ✅")
        except Exception as e:
            print(f"  - {name}: Failed ❌ ({str(e)[:50]}...)")

if __name__ == "__main__":
    main()