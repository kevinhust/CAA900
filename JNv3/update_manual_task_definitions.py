#!/usr/bin/env python3
import boto3
import json

def update_task_definitions():
    """使用手动构建的 AMD64 镜像更新任务定义"""
    ecs_client = boto3.client('ecs', region_name='us-east-1')
    
    # 后端任务定义 - 使用手动构建的 AMD64 镜像
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
                        "name": "WORKERS",
                        "value": "2"
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
    
    # 前端任务定义 - 使用手动构建的 AMD64 镜像
    frontend_task_def = {
        "containerDefinitions": [
            {
                "name": "frontend",
                "image": "039444453392.dkr.ecr.us-east-1.amazonaws.com/jobquest-navigator-v3-frontend:manual-amd64-20250801-144950",
                "cpu": 0,
                "portMappings": [
                    {
                        "containerPort": 3000,
                        "hostPort": 3000,
                        "protocol": "tcp"
                    }
                ],
                "essential": True,
                "environment": [
                    {
                        "name": "NODE_ENV",
                        "value": "production"
                    },
                    {
                        "name": "REACT_APP_ENV",
                        "value": "production"
                    },
                    {
                        "name": "REACT_APP_API_URL",
                        "value": "http://jobquest-navigator-v3-alb-1532571588.us-east-1.elb.amazonaws.com/api"
                    },
                    {
                        "name": "REACT_APP_GRAPHQL_URL",
                        "value": "http://jobquest-navigator-v3-alb-1532571588.us-east-1.elb.amazonaws.com/graphql"
                    }
                ],
                "mountPoints": [],
                "volumesFrom": [],
                "logConfiguration": {
                    "logDriver": "awslogs",
                    "options": {
                        "awslogs-group": "/ecs/jobquest-navigator-v3/frontend",
                        "awslogs-region": "us-east-1",
                        "awslogs-stream-prefix": "ecs"
                    }
                },
                "systemControls": []
            }
        ],
        "family": "jobquest-navigator-v3-frontend",
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
        print("🔄 注册后端任务定义...")
        backend_response = ecs_client.register_task_definition(**backend_task_def)
        backend_revision = backend_response['taskDefinition']['revision']
        print(f"✅ 后端任务定义已注册: revision {backend_revision}")
        
        # 注册新的前端任务定义
        print("🔄 注册前端任务定义...")
        frontend_response = ecs_client.register_task_definition(**frontend_task_def)
        frontend_revision = frontend_response['taskDefinition']['revision']
        print(f"✅ 前端任务定义已注册: revision {frontend_revision}")
        
        # 更新 ECS 服务
        print("🔄 更新 ECS 服务...")
        
        # 更新后端服务
        ecs_client.update_service(
            cluster='jobquest-navigator-v3-cluster',
            service='jobquest-navigator-v3-backend-service',
            taskDefinition=f'jobquest-navigator-v3-backend:{backend_revision}',
            forceNewDeployment=True,
            desiredCount=1
        )
        print("✅ 后端服务已更新")
        
        # 更新前端服务
        ecs_client.update_service(
            cluster='jobquest-navigator-v3-cluster',
            service='jobquest-navigator-v3-frontend-service',
            taskDefinition=f'jobquest-navigator-v3-frontend:{frontend_revision}',
            forceNewDeployment=True,
            desiredCount=1
        )
        print("✅ 前端服务已更新")
        
        print(f"\n🎉 所有服务更新成功!")
        print(f"📦 后端任务定义: jobquest-navigator-v3-backend:{backend_revision}")
        print(f"📦 前端任务定义: jobquest-navigator-v3-frontend:{frontend_revision}")
        print(f"🏷️  后端镜像: manual-amd64-20250801-144937")
        print(f"🏷️  前端镜像: manual-amd64-20250801-144950")
        
    except Exception as e:
        print(f"❌ 错误: {e}")
        raise

if __name__ == "__main__":
    update_task_definitions()