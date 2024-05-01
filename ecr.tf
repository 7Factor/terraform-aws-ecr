locals {
  push_account_arn_list = formatlist("arn:aws:iam::%s:root", var.push_account_list)
  pull_account_arn_list = formatlist("arn:aws:iam::%s:root", var.pull_account_list)
}

resource "aws_ecr_repository" "repos" {
  for_each = var.repository_list
  name     = each.value
}

data "aws_ecr_lifecycle_policy_document" "lifecycle_policy" {
  rule {
    priority    = 1
    description = "Keep last ${var.images_to_keep} images with `any` tag"
    selection {
      tag_status   = "any"
      count_type   = "imageCountMoreThan"
      count_number = var.images_to_keep
    }
    action {
      type = "expire"
    }
  }
}

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  for_each   = var.repository_list
  repository = each.value

  depends_on = [aws_ecr_repository.repos]

  policy = data.aws_ecr_lifecycle_policy_document.lifecycle_policy.json
}

data "aws_iam_policy_document" "policy_document" {
  statement {
    sid    = "AllowCrossAccountPull"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = local.pull_account_arn_list
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
  }
  statement {
    sid    = "AllowCrossAccountPush"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = local.push_account_arn_list
    }
    actions = [
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
  }
}

resource "aws_ecr_repository_policy" "policy" {
  for_each   = var.repository_list
  repository = each.value

  depends_on = [aws_ecr_repository.repos]

  policy = data.aws_iam_policy_document.policy_document.json
}