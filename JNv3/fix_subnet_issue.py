#!/usr/bin/env python3
"""
Fix database subnet issue by manually handling RDS network interface detachment
"""
import boto3
import time
import sys

def fix_database_subnet_issue():
    """Fix the database subnet ENI detachment issue"""
    
    ec2_client = boto3.client('ec2', region_name='us-east-1')
    rds_client = boto3.client('rds', region_name='us-east-1')
    
    print("🔍 Analyzing RDS network interface issue...")
    
    try:
        # Get database instance info
        db_instances = rds_client.describe_db_instances(
            DBInstanceIdentifier='jobquest-navigator-v3-db-d2b0b54a'
        )
        
        if not db_instances['DBInstances']:
            print("❌ Database instance not found")
            return False
            
        db_instance = db_instances['DBInstances'][0]
        print(f"📊 Database status: {db_instance['DBInstanceStatus']}")
        
        # Get associated ENIs
        db_subnet_group = db_instance['DBSubnetGroup']['DBSubnetGroupName']
        print(f"📊 DB Subnet Group: {db_subnet_group}")
        
        # List network interfaces for RDS
        enis = ec2_client.describe_network_interfaces(
            Filters=[
                {'Name': 'requester-id', 'Values': ['amazon-rds']},
                {'Name': 'status', 'Values': ['in-use']},
                {'Name': 'description', 'Values': ['RDS NetworkInterface']}
            ]
        )
        
        print(f"📊 Found {len(enis['NetworkInterfaces'])} RDS ENIs")
        
        for eni in enis['NetworkInterfaces']:
            eni_id = eni['NetworkInterfaceId']
            subnet_id = eni['SubnetId']
            print(f"📊 ENI {eni_id} in subnet {subnet_id}")
            
            # Check if this ENI is in the problematic subnet
            if subnet_id == 'subnet-0b2a5d67b81f1dd6e':
                print(f"🎯 Found problematic ENI: {eni_id}")
                
                # The issue is that we need to wait for RDS to release the ENI
                # Let's try to modify the DB subnet group first
                print("🔄 Attempting to update DB subnet group...")
                
                # Get new subnet IDs
                new_subnets = ['subnet-0f1145df72787ced4']  # This should be the new database subnet
                
                try:
                    rds_client.modify_db_subnet_group(
                        DBSubnetGroupName=db_subnet_group,
                        SubnetIds=new_subnets,
                        DBSubnetGroupDescription='Updated subnet group for JobQuest Navigator v3'
                    )
                    print("✅ DB subnet group update initiated")
                    
                    # Wait for the update to complete
                    print("⏳ Waiting for DB subnet group update...")
                    time.sleep(30)
                    
                    return True
                    
                except Exception as e:
                    print(f"❌ Failed to update DB subnet group: {e}")
                    return False
        
        print("✅ No problematic ENIs found")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = fix_database_subnet_issue()
    sys.exit(0 if success else 1)