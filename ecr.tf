data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "repos" {
  count = "${length(var.repository_list)}"
  name  = "${var.repository_list[count.index]}"
}

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  count      = "${length(var.repository_list)}"
  repository = "${var.repository_list[count.index]}"

  depends_on = ["aws_ecr_repository.repos"]

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

data "template_file" "account_template" {
  count = "${length(var.account_list)}"

  template = <<EOF

  "AWS": "arn:aws:iam::$${account_id}:root",

EOF

  vars {
    account_id = "${var.account_list[count.index]}"
  }
}

resource "aws_ecr_repository_policy" "repository_policy" {
  count      = "${length(var.repository_list)}"
  repository = "${var.repository_list[count.index]}"

  depends_on = ["aws_ecr_repository.repos"]

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "AllowCrossAccountPull",
            "Effect": "Allow",
            "Principal": {
                ${template_file.account_template.rendered}
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ]
        },
        {
            "Sid": "AllowAll",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": [
                "ecr:*"
            ]
        }
    ]
}
EOF
}
