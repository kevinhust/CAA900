# ECR Module Variables for JobQuest Navigator v3

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
}

variable "repositories" {
  description = "List of repository names to create"
  type        = list(string)
  default     = ["backend", "frontend"]
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "The encryption type to use for the repository"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be either AES256 or KMS."
  }
}

variable "kms_key_id" {
  description = "The KMS key ID to use for encryption (only required if encryption_type is KMS)"
  type        = string
  default     = null
}

variable "max_image_count" {
  description = "Maximum number of images to keep"
  type        = number
  default     = 10
}

variable "untagged_image_days" {
  description = "Number of days to keep untagged images"
  type        = number
  default     = 1
}

variable "enable_cross_account_access" {
  description = "Enable cross-account access to ECR repositories"
  type        = bool
  default     = false
}

variable "cross_account_arns" {
  description = "List of cross-account ARNs to allow access"
  type        = list(string)
  default     = []
}

variable "allowed_principals" {
  description = "List of IAM principals allowed to push/pull images"
  type        = list(string)
  default     = []
}

variable "enable_replication" {
  description = "Enable ECR replication to another region"
  type        = bool
  default     = false
}

variable "replication_region" {
  description = "Target region for ECR replication"
  type        = string
  default     = "us-west-2"
}

variable "enable_public_repositories" {
  description = "Create public ECR repositories"
  type        = bool
  default     = false
}

variable "public_repositories" {
  description = "List of public repository names to create"
  type        = list(string)
  default     = []
}

variable "repository_descriptions" {
  description = "Map of repository descriptions"
  type        = map(string)
  default     = {}
}

variable "enable_scan_logging" {
  description = "Enable CloudWatch logging for ECR scanning"
  type        = bool
  default     = false
}

variable "scan_log_retention_days" {
  description = "Number of days to retain scan logs"
  type        = number
  default     = 7
}

variable "enable_scan_notifications" {
  description = "Enable SNS notifications for scan results"
  type        = bool
  default     = false
}

variable "notification_emails" {
  description = "List of email addresses for scan notifications"
  type        = list(string)
  default     = []
}