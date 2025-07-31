# IAM Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecr_repository_arns" {
  description = "List of ECR repository ARNs"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for application access"
  type        = string
}

variable "enable_lambda_functions" {
  description = "Enable Lambda function IAM roles"
  type        = bool
  default     = false
}

variable "enable_codepipeline" {
  description = "Enable CodePipeline IAM roles"
  type        = bool
  default     = false
}

variable "enable_codebuild" {
  description = "Enable CodeBuild IAM roles"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_access" {
  description = "Enable enhanced CloudWatch access"
  type        = bool
  default     = true
}

variable "enable_secrets_manager_access" {
  description = "Enable Secrets Manager access"
  type        = bool
  default     = true
}

variable "enable_parameter_store_access" {
  description = "Enable Parameter Store access"
  type        = bool
  default     = true
}

variable "custom_policies" {
  description = "List of custom policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "trusted_role_arns" {
  description = "List of trusted role ARNs for cross-account access"
  type        = list(string)
  default     = []
}

variable "trusted_account_ids" {
  description = "List of trusted AWS account IDs for cross-account access"
  type        = list(string)
  default     = []
}

variable "external_id" {
  description = "External ID for cross-account role assumption"
  type        = string
  default     = null
}

variable "create_cross_account_role" {
  description = "Create cross-account monitoring role"
  type        = bool
  default     = false
}

variable "create_ec2_instance_profile" {
  description = "Create EC2 instance profile"
  type        = bool
  default     = false
}

variable "create_kms_key" {
  description = "Create KMS key for encryption"
  type        = bool
  default     = false
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}

variable "create_lambda_roles" {
  description = "Create Lambda execution roles"
  type        = bool
  default     = false
}

variable "create_codebuild_role" {
  description = "Create CodeBuild service role"
  type        = bool
  default     = false
}

variable "create_service_linked_roles" {
  description = "Create AWS service-linked roles"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}