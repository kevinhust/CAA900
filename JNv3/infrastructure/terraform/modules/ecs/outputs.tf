# ECS Module Outputs

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "backend_service_id" {
  description = "ID of the backend ECS service"
  value       = aws_ecs_service.backend.id
}

output "backend_service_name" {
  description = "Name of the backend ECS service"
  value       = aws_ecs_service.backend.name
}

output "backend_service_arn" {
  description = "ARN of the backend ECS service"
  value       = aws_ecs_service.backend.id
}

output "frontend_service_id" {
  description = "ID of the frontend ECS service"
  value       = var.deploy_frontend_to_ecs ? aws_ecs_service.frontend[0].id : null
}

output "frontend_service_name" {
  description = "Name of the frontend ECS service"
  value       = var.deploy_frontend_to_ecs ? aws_ecs_service.frontend[0].name : null
}

output "frontend_service_arn" {
  description = "ARN of the frontend ECS service"
  value       = var.deploy_frontend_to_ecs ? aws_ecs_service.frontend[0].id : null
}

output "backend_task_definition_arn" {
  description = "ARN of the backend task definition"
  value       = aws_ecs_task_definition.backend.arn
}

output "frontend_task_definition_arn" {
  description = "ARN of the frontend task definition"
  value       = var.deploy_frontend_to_ecs ? aws_ecs_task_definition.frontend[0].arn : null
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "backend_log_group_name" {
  description = "Name of the backend CloudWatch log group"
  value       = aws_cloudwatch_log_group.backend.name
}

output "frontend_log_group_name" {
  description = "Name of the frontend CloudWatch log group"
  value       = aws_cloudwatch_log_group.frontend.name
}

output "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  value       = var.enable_service_discovery ? aws_service_discovery_private_dns_namespace.main[0].id : null
}

output "backend_service_discovery_arn" {
  description = "ARN of the backend service discovery service"
  value       = var.enable_service_discovery ? aws_service_discovery_service.backend[0].arn : null
}