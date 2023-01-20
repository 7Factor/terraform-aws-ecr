terraform {
  required_version = ">=0.12.24"
}

resource "aws_ecr_repository" "repos" {
  for_each = var.repository_list
  name     = each.value
}

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  for_each   = var.repository_list
  repository = each.value

  depends_on = [aws_ecr_repository.repos]

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last ${var.images_to_keep} images with `any` tag",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.images_to_keep}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

data "template_file" "push_allowed_policy" {
  template = <<EOF
{
    "Sid": "AllowCrossAccountPush",
    "Effect": "Allow",
    "Principal": {
        "AWS": [${join(",", formatlist("\"arn:aws:iam::%s:root\"", var.push_account_list))}]
    },
    "Action": [
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
    ]
}
EOF
}

data "template_file" "pull_allowed_policy" {
  template = <<EOF
{
    "Sid": "AllowCrossAccountPull",
    "Effect": "Allow",
    "Principal": {
        "AWS": [${join(",", formatlist("\"arn:aws:iam::%s:root\"", var.pull_account_list))}]
    },
    "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
    ]
}
EOF
}

data "aws_iam_policy_document" "pull_allowed_lambda_policy" {
  statement {
    sid    = "AllowCrossAccountLambdaImagePull"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy"
    ]

    principals {
      type        = "AWS"
      identifiers = join(",", formatlist("\"arn:aws:iam::%s:root\"", var.pull_account_list))
    }

    # need lambda to assume the role
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }

    # only if source ars are like below
    condition {
      test     = "StringLike"
      variable = "aws:sourceArn"

      values = join(",", formatlist("\"arn:aws:lambda:*:%s:function:*\"", var.pull_account_list))
    }
  }
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
  length(var.pull_account_list) == 0 ? "" : data.template_file.pull_allowed_policy.rendered,
  length(var.push_account_list) == 0 ? "" : data.template_file.push_allowed_policy.rendered,
  var.allow_lambda_pull ? data.aws_iam_policy_document.pull_allowed_lambda_policy.json : ""
])))}
    ]
}
EOF
}
