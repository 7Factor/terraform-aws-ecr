locals {
  push_account_arn = join(",", formatlist("arn:aws:iam::%s:root", var.push_account_list))
  pull_account_arn = join(",", formatlist("arn:aws:iam::%s:root", var.pull_account_list))
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

resource "aws_ecr_repository_policy" "policy" {
  for_each   = var.repository_list
  repository = each.value

  depends_on = [aws_ecr_repository.repos]

  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      join(",", compact(tolist([
        length(var.pull_account_list) == 0 ? null : {
          Sid    = "AllowCrossAccountPull",
          Effect = "Allow",
          Principal = {
            AWS = [local.pull_account_arn]
          },
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability"
          ]
        },
        length(var.push_account_list) == 0 ? null : {
          Sid    = "AllowCrossAccountPush",
          Effect = "Allow",
          Principal = {
            AWS = [local.push_account_arn]
          },
          Action = [
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload"
          ]
        }
      ])))
    ]
  })
}