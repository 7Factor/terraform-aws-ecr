locals {
  push_account_list = join(",", formatlist("\"arn:aws:iam::%s:root\"", var.push_account_list))
  pull_account_list = join(",", formatlist("\"arn:aws:iam::%s:root\"", var.pull_account_list))
  lifecycle_policy  = templatefile("${path.module}/templates/lifecycle_policy.tftpl", { images_to_keep = var.images_to_keep })
  push_policy       = templatefile("${path.module}/templates/push_policy.tftpl", { push_account_list = local.push_account_list })
  pull_policy       = templatefile("${path.module}/templates/pull_policy.tftpl", { pull_account_list = local.pull_account_list })
  repo_policy_statement = (join(",", compact(tolist([
    length(var.pull_account_list) == 0 ? "" : local.pull_policy,
    length(var.push_account_list) == 0 ? "" : local.push_policy
  ]))))
  repo_policy = templatefile("${path.module}/templates/repo_policy.tftpl", { repo_policy_statement = local.repo_policy_statement })
}

resource "aws_ecr_repository" "repos" {
  for_each = var.repository_list
  name     = each.value
}

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  for_each   = var.repository_list
  repository = each.value

  depends_on = [aws_ecr_repository.repos]

  policy = local.lifecycle_policy
}

resource "aws_ecr_repository_policy" "policy" {
  for_each   = var.repository_list
  repository = each.value

  depends_on = [aws_ecr_repository.repos]

  policy = local.repo_policy
}
