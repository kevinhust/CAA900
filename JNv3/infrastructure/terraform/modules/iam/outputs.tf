# IAM Module Outputs

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.name
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.ecs_task.name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = var.enable_lambda_functions ? aws_iam_role.lambda_execution[0].arn : null
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = var.enable_lambda_functions ? aws_iam_role.lambda_execution[0].name : null
}

output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline service role"
  value       = null
}

output "codepipeline_role_name" {
  description = "Name of the CodePipeline service role"
  value       = null
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild service role"
  value       = null
}

output "codebuild_role_name" {
  description = "Name of the CodeBuild service role"
  value       = null
}

output "custom_policy_arns" {
  description = "ARNs of custom IAM policies created"
  value = [
    aws_iam_policy.ecs_task_execution_custom.arn
  ]
}

output "all_role_arns" {
  description = "Map of all IAM role ARNs created"
  value = {
    ecs_task_execution = aws_iam_role.ecs_task_execution.arn
    ecs_task          = aws_iam_role.ecs_task.arn
    lambda_execution  = null
    codepipeline      = null
    codebuild         = null
  }
}