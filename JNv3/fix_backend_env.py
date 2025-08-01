#!/usr/bin/env python3
import boto3
import json

def fix_backend_environment():
    """修复后端任务定义的环境变量"""
    ecs_client = boto3.client('ecs', region_name='us-east-1')
    
    # 后端任务定义 - 添加缺失的环境变量
    backend_task_def = {
        "containerDefinitions": [
            {
                "name": "backend",
                "image": "039444453392.dkr.ecr.us-east-1.amazonaws.com/jobquest-navigator-v3-backend:manual-amd64-20250801-144937",
                "cpu": 0,
                "portMappings": [
                    {
                        "containerPort": 8000,
                        "hostPort": 8000,
                        "protocol": "tcp"
                    }
                ],
                "essential": True,
                "environment": [
                    {
                        "name": "DATABASE_URL",
                        "value": "postgresql://jobquest_user:SecurePass2024JobQuest!@jobquest-navigator-v3-db-d2b0b54a.cmpaeyc24qtl.us-east-1.rds.amazonaws.com:5432/jobquest"
                    },
                    {
                        "name": "SECRET_KEY", 
                        "value": "super-secret-key-for-production-jobquest-navigator-v3-2024"
                    },
                    {
                        "name": "AWS_ACCESS_KEY_ID",
                        "value": "dummy-for-ecs-role"
                    },
                    {
                        "name": "AWS_SECRET_ACCESS_KEY",
                        "value": "dummy-for-ecs-role"
                    },
                    {
                        "name": "WORKERS",
                        "value": "1"
                    },
                    {
                        "name": "ENVIRONMENT",
                        "value": "production"
                    },
                    {
                        "name": "AWS_DEFAULT_REGION",
                        "value": "us-east-1"
                    },
                    {
                        "name": "CORS_ORIGINS",
                        "value": "http://jobquest-navigator-v3-alb-1532571588.us-east-1.elb.amazonaws.com"
                    },
                    {
                        "name": "LOG_LEVEL",
                        "value": "info"
                    },
                    {
                        "name": "DEBUG",
                        "value": "false"
                    }
                ],
                "mountPoints": [],
                "volumesFrom": [],
                "logConfiguration": {
                    "logDriver": "awslogs",
                    "options": {
                        "awslogs-group": "/ecs/jobquest-navigator-v3/backend",
                        "awslogs-region": "us-east-1",
                        "awslogs-stream-prefix": "ecs"
                    }
                },
                "systemControls": []
            }
        ],
        "family": "jobquest-navigator-v3-backend",
        "executionRoleArn": "arn:aws:iam::039444453392:role/jobquest-navigator-v3-ecs-execution-role",
        "networkMode": "awsvpc",
        "volumes": [],
        "requiresCompatibilities": [
            "FARGATE"
        ],
        "cpu": "512",
        "memory": "1024"
    }
    
    try:
        # 注册新的后端任务定义
        print("🔄 注册修复的后端任务定义...")
        backend_response = ecs_client.register_task_definition(**backend_task_def)
        backend_revision = backend_response['taskDefinition']['revision']
        print(f"✅ 后端任务定义已注册: revision {backend_revision}")
        
        # 更新 ECS 服务
        print("🔄 更新后端服务...")
        ecs_client.update_service(
            cluster='jobquest-navigator-v3-cluster',
            service='jobquest-navigator-v3-backend-service',
            taskDefinition=f'jobquest-navigator-v3-backend:{backend_revision}',
            forceNewDeployment=True,
            desiredCount=1
        )
        print("✅ 后端服务已更新")
        
        print(f"\n🎉 后端环境变量修复完成!")
        print(f"📦 新任务定义: jobquest-navigator-v3-backend:{backend_revision}")
        print(f"🔧 添加的环境变量: SECRET_KEY, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, DEBUG")
        
    except Exception as e:
        print(f"❌ 错误: {e}")
        raise

if __name__ == "__main__":
    fix_backend_environment()