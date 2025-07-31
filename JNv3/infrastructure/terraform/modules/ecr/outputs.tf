# ECR Module Outputs for JobQuest Navigator v3

output "repository_arns" {
  description = "ARNs of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.arn }
}

output "repository_urls" {
  description = "URLs of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.repository_url }
}

output "repository_names" {
  description = "Names of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.name }
}

output "registry_id" {
  description = "The registry ID where the repository was created"
  value       = try(values(aws_ecr_repository.repositories)[0].registry_id, "")
}

output "repository_registry_ids" {
  description = "Registry IDs of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.registry_id }
}

output "public_repository_urls" {
  description = "URLs of the public ECR repositories"
  value = var.enable_public_repositories ? {
    for k, v in aws_ecrpublic_repository.public_repositories : k => v.repository_uri
  } : {}
}