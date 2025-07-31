# CloudWatch Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_names" {
  description = "List of ECS service names to monitor"
  type        = list(string)
  default     = []
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "elasticache_cluster_id" {
  description = "ElastiCache cluster identifier"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for monitoring"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix for monitoring"
  type        = string
}

variable "alarm_actions" {
  description = "List of alarm actions (SNS topic ARNs)"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of OK actions (SNS topic ARNs)"
  type        = list(string)
  default     = []
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch logs retention in days"
  type        = number
  default     = 14
}

variable "alert_email_addresses" {
  description = "List of email addresses for alert notifications"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = null
}

variable "create_log_groups" {
  description = "Create additional CloudWatch log groups"
  type        = bool
  default     = true
}

variable "create_log_metric_filters" {
  description = "Whether to create log metric filters"
  type        = bool
  default     = false
}

variable "database_connection_threshold" {
  description = "Database connection count threshold for alarms"
  type        = number
  default     = 80
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = false
}

variable "ecs_cluster_arn" {
  description = "ECS cluster ARN for EventBridge rules"
  type        = string
  default     = ""
}

variable "enable_cost_anomaly_detection" {
  description = "Enable cost anomaly detection"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}