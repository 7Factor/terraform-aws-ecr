output "ecr_repository_urls" {
  value       = aws_ecr_repository.repos
  description = "A list of urls of the repositories that were created."
}
