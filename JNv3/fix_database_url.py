#!/usr/bin/env python3
import boto3
import json

def fix_database_url():
    """修复后端任务定义的数据库URL格式"""
    ecs_client = boto3.client('ecs', region_name='us-east-1')
    
    # 获取当前任务定义
    current_task_def = ecs_client.describe_task_definition(
        taskDefinition='jobquest-navigator-v3-backend'
    )['taskDefinition']
    
    # 修改数据库URL格式
    for env_var in current_task_def['containerDefinitions'][0]['environment']:
        if env_var['name'] == 'DATABASE_URL':
            old_url = env_var['value']
            # 将 postgresql:// 改为 postgresql+asyncpg://
            new_url = old_url.replace('postgresql://', 'postgresql+asyncpg://')
            env_var['value'] = new_url
            print(f"📝 修改数据库URL:")
            print(f"   原URL: {old_url}")
            print(f"   新URL: {new_url}")
            break
    
    # 准备新的任务定义
    new_task_def = {
        'family': current_task_def['family'],
        'networkMode': current_task_def['networkMode'],
        'requiresCompatibilities': current_task_def['requiresCompatibilities'],
        'cpu': current_task_def['cpu'],
        'memory': current_task_def['memory'],
        'executionRoleArn': current_task_def['executionRoleArn'],
        'containerDefinitions': current_task_def['containerDefinitions']
    }
    
    # 只有在taskRoleArn存在时才添加
    if current_task_def.get('taskRoleArn'):
        new_task_def['taskRoleArn'] = current_task_def['taskRoleArn']
    
    try:
        # 注册新的任务定义
        print("🔄 注册修复的任务定义...")
        response = ecs_client.register_task_definition(**new_task_def)
        new_revision = response['taskDefinition']['revision']
        print(f"✅ 任务定义已注册: revision {new_revision}")
        
        # 更新ECS服务
        print("🔄 更新后端服务...")
        ecs_client.update_service(
            cluster='jobquest-navigator-v3-cluster',
            service='jobquest-navigator-v3-backend-service',
            taskDefinition=f'jobquest-navigator-v3-backend:{new_revision}',
            forceNewDeployment=True
        )
        print("✅ 后端服务已更新")
        
        print(f"\n🎉 数据库URL格式修复完成!")
        print(f"📦 新任务定义: jobquest-navigator-v3-backend:{new_revision}")
        print(f"🔧 修改内容: 使用 postgresql+asyncpg:// 而非 postgresql://")
        
    except Exception as e:
        print(f"❌ 错误: {e}")
        raise

if __name__ == "__main__":
    fix_database_url()