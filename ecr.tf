locals {
  lifecycle_policy    = templatefile("${path.module}/templates/lifecycle_policy.tftpl", { images_to_keep = var.images_to_keep })
  push_allowed_policy = templatefile("${path.module}/templates/push_policy.tftpl", { push_account_list = "${join(",", formatlist("\"arn:aws:iam::%s:root\"", var.push_account_list))}" })
  pull_allowed_policy = templatefile("${path.module}/templates/pull_policy.tftpl", { pull_account_list = "${join(",", formatlist("\"arn:aws:iam::%s:root\"", var.pull_account_list))}" })
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

# This is the stupidest terraform I've ever had to write. Good lord kill me.
resource "aws_ecr_repository_policy" "policy" {
  for_each   = var.repository_list
  repository = each.value

  depends_on = [aws_ecr_repository.repos]

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
      ${join(",", compact(tolist([
  length(var.pull_account_list) == 0 ? "" : local.pull_allowed_policy,
  length(var.push_account_list) == 0 ? "" : local.push_allowed_policy
])))}
    ]
}
EOF
}
