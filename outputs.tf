output "ecr_repository_urls" {
  value       = values(aws_ecr_repository.repos)[0]
  description = "A list of urls of the repositories that were created."
}

output "ecr_repository_urls2" {
  value       = values(aws_ecr_repository.repos)[0].repository_url
  description = "A list of urls of the repositories that were created."
}
