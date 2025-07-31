# ECS Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "backend_security_group_id" {
  description = "Security group ID for backend service"
  type        = string
}

variable "frontend_security_group_id" {
  description = "Security group ID for frontend service"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN for backend load balancer"
  type        = string
}

variable "frontend_target_group_arn" {
  description = "Target group ARN for frontend load balancer"
  type        = string
  default     = ""
}

variable "backend_image_uri" {
  description = "Container image URI for backend"
  type        = string
}

variable "frontend_image_uri" {
  description = "Container image URI for frontend"
  type        = string
}

variable "backend_cpu" {
  description = "CPU units for backend container"
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Memory for backend container in MB"
  type        = number
  default     = 1024
}

variable "backend_count" {
  description = "Desired number of backend containers"
  type        = number
  default     = 2
}

variable "frontend_cpu" {
  description = "CPU units for frontend container"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory for frontend container in MB"
  type        = number
  default     = 512
}

variable "frontend_count" {
  description = "Desired number of frontend containers"
  type        = number
  default     = 2
}

variable "environment_variables" {
  description = "Environment variables for containers"
  type        = map(string)
  default     = {}
}

variable "secrets_variables" {
  description = "Secret variables from AWS Secrets Manager"
  type        = map(string)
  default     = null
}

variable "graphql_endpoint" {
  description = "GraphQL endpoint URL for frontend"
  type        = string
  default     = ""
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for task policy"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "deploy_frontend_to_ecs" {
  description = "Deploy frontend to ECS (false for S3 hosting)"
  type        = bool
  default     = false
}

variable "enable_service_discovery" {
  description = "Enable service discovery"
  type        = bool
  default     = false
}

variable "backend_max_capacity" {
  description = "Maximum number of backend containers for auto scaling"
  type        = number
  default     = 10
}

variable "backend_min_capacity" {
  description = "Minimum number of backend containers for auto scaling"
  type        = number
  default     = 1
}

variable "cpu_target_value" {
  description = "Target CPU utilization for auto scaling"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target memory utilization for auto scaling"
  type        = number
  default     = 80
}

variable "alarm_actions" {
  description = "List of alarm actions (SNS topic ARNs)"
  type        = list(string)
  default     = []
}

variable "enable_spot_instances" {
  description = "Enable Fargate Spot instances"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}