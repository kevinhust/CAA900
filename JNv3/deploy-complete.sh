#!/bin/bash

# JobQuest Navigator v3 - 完整一键部署脚本
# 作者: Claude AI Assistant
# 日期: 2025-08-01

set -e  # 遇到错误立即退出

# 配置变量
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="039444453392"
export ECR_BACKEND_REPO="jobquest-navigator-v3-backend"
export ECR_FRONTEND_REPO="jobquest-navigator-v3-frontend"
export ECS_CLUSTER="jobquest-navigator-v3-cluster"
export ECS_BACKEND_SERVICE="jobquest-navigator-v3-backend-service"
export ECS_FRONTEND_SERVICE="jobquest-navigator-v3-frontend-service"
export LOAD_BALANCER_DNS="jobquest-navigator-v3-alb-1532571588.us-east-1.elb.amazonaws.com"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查前置条件
check_prerequisites() {
    log_info "检查前置条件..."
    
    # 检查 AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI 未安装，请先安装 AWS CLI"
        exit 1
    fi
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    # 检查 AWS 认证
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS 认证失败，请检查 AWS credentials"
        exit 1
    fi
    
    log_success "前置条件检查通过"
}

# ECR 登录
ecr_login() {
    log_info "登录到 Amazon ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    log_success "ECR 登录成功"
}

# 构建并推送镜像
build_and_push() {
    log_info "构建并推送 Docker 镜像..."
    
    # 构建前端镜像
    log_info "构建前端镜像..."
    cd apps/frontend-react
    docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_FRONTEND_REPO:latest .
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_FRONTEND_REPO:latest
    log_success "前端镜像构建并推送成功"
    
    # 构建后端镜像
    log_info "构建后端镜像..."
    cd ../backend-fastapi
    docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND_REPO:latest .
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND_REPO:latest
    log_success "后端镜像构建并推送成功"
    
    cd ../../
}

# 更新 ECS 服务
update_ecs_services() {
    log_info "更新 ECS 服务..."
    
    # 更新后端服务
    log_info "更新后端服务..."
    aws ecs describe-task-definition --task-definition jobquest-navigator-v3-backend --query taskDefinition > backend-task-def.json
    
    # 使用 Python 更新任务定义
    python3 << EOF
import json
import sys

try:
    with open('backend-task-def.json', 'r') as f:
        task_def = json.load(f)
    
    # 更新镜像 URL
    for container in task_def['containerDefinitions']:
        if container['name'] == 'backend':
            container['image'] = '$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND_REPO:latest'
    
    # 移除不需要的字段
    fields_to_remove = ['taskDefinitionArn', 'revision', 'status', 'requiresAttributes', 
                       'placementConstraints', 'compatibilities', 'registeredAt', 'registeredBy']
    for field in fields_to_remove:
        task_def.pop(field, None)
    
    with open('backend-task-def-new.json', 'w') as f:
        json.dump(task_def, f, indent=2)
    
    print('Backend task definition updated successfully')
except Exception as e:
    print(f'Error updating backend task definition: {e}')
    sys.exit(1)
EOF
    
    # 注册新的任务定义
    aws ecs register-task-definition --cli-input-json file://backend-task-def-new.json > /dev/null
    
    # 更新前端服务
    log_info "更新前端服务..."
    aws ecs describe-task-definition --task-definition jobquest-navigator-v3-frontend --query taskDefinition > frontend-task-def.json
    
    python3 << EOF
import json
import sys

try:
    with open('frontend-task-def.json', 'r') as f:
        task_def = json.load(f)
    
    # 更新镜像 URL
    for container in task_def['containerDefinitions']:
        if container['name'] == 'frontend':
            container['image'] = '$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_FRONTEND_REPO:latest'
    
    # 移除不需要的字段
    fields_to_remove = ['taskDefinitionArn', 'revision', 'status', 'requiresAttributes', 
                       'placementConstraints', 'compatibilities', 'registeredAt', 'registeredBy']
    for field in fields_to_remove:
        task_def.pop(field, None)
    
    with open('frontend-task-def-new.json', 'w') as f:
        json.dump(task_def, f, indent=2)
    
    print('Frontend task definition updated successfully')
except Exception as e:
    print(f'Error updating frontend task definition: {e}')
    sys.exit(1)
EOF
    
    # 注册新的任务定义
    aws ecs register-task-definition --cli-input-json file://frontend-task-def-new.json > /dev/null
    
    # 强制部署新版本
    log_info "部署新版本到 ECS..."
    aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_BACKEND_SERVICE --force-new-deployment --desired-count 1 > /dev/null
    aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_FRONTEND_SERVICE --force-new-deployment --desired-count 1 > /dev/null
    
    log_success "ECS 服务更新成功"
}

# 等待部署完成
wait_for_deployment() {
    log_info "等待部署完成..."
    
    # 等待服务稳定
    log_info "等待后端服务稳定..."
    aws ecs wait services-stable --cluster $ECS_CLUSTER --services $ECS_BACKEND_SERVICE
    
    log_info "等待前端服务稳定..."
    aws ecs wait services-stable --cluster $ECS_CLUSTER --services $ECS_FRONTEND_SERVICE
    
    log_success "部署完成，服务已稳定"
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    # 检查服务状态
    BACKEND_STATUS=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_BACKEND_SERVICE --query 'services[0].[runningCount,desiredCount]' --output text)
    FRONTEND_STATUS=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_FRONTEND_SERVICE --query 'services[0].[runningCount,desiredCount]' --output text)
    
    echo "后端服务状态: $BACKEND_STATUS"
    echo "前端服务状态: $FRONTEND_STATUS"
    
    # 测试负载均衡器
    log_info "测试应用程序可访问性..."
    
    sleep 30  # 等待负载均衡器更新
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$LOAD_BALANCER_DNS || echo "000")
    
    if [ "$HTTP_STATUS" = "200" ]; then
        log_success "✅ 应用程序部署成功！"
        echo ""
        echo "🌐 应用程序访问地址："
        echo "   前端: http://$LOAD_BALANCER_DNS"
        echo "   后端 API: http://$LOAD_BALANCER_DNS/api"
        echo "   GraphQL: http://$LOAD_BALANCER_DNS/graphql"
        echo "   健康检查: http://$LOAD_BALANCER_DNS/health"
    else
        log_warning "⚠️  应用程序可能还在启动中，HTTP状态码: $HTTP_STATUS"
        echo "请稍等几分钟后再次检查: http://$LOAD_BALANCER_DNS"
    fi
}

# 清理临时文件
cleanup() {
    log_info "清理临时文件..."
    rm -f backend-task-def.json frontend-task-def.json backend-task-def-new.json frontend-task-def-new.json
    log_success "清理完成"
}

# 主函数
main() {
    echo "🚀 JobQuest Navigator v3 - 一键部署脚本"
    echo "================================================"
    echo ""
    
    check_prerequisites
    ecr_login
    build_and_push
    update_ecs_services
    wait_for_deployment
    verify_deployment
    cleanup
    
    echo ""
    echo "🎉 部署流程完成！"
    echo "如有问题，请检查 AWS ECS 控制台中的服务状态。"
}

# 执行主函数
main "$@"