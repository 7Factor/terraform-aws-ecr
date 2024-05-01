locals {
  push_account_arn_list = formatlist("arn:aws:iam::%s:root", var.push_account_list)
  pull_account_arn_list = formatlist("arn:aws:iam::%s:root", var.pull_account_list)
}

resource "aws_ecr_repository" "repos" {
  for_each = var.repository_list
  name     = each.value
}

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  for_each   = var.repository_list
  repository = each.value

  depends_on = [aws_ecr_repository.repos]

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last ${var.images_to_keep} images with `any` tag",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = var.images_to_keep
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "test" {
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
}

resource "aws_ecr_repository_policy" "policy" {
  for_each   = var.repository_list
  repository = each.value

  depends_on = [aws_ecr_repository.repos]

  policy = data.aws_iam_policy_document.test.json
}