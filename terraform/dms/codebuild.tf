### Code Build ###
resource "aws_ecr_repository" "dms" {
  name                 = "dms"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}
data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}
resource "aws_iam_policy" "code_build_policy" {
  name        = "dms-codebuild-policy"
  path        = "/"
  description = "DMS Code Build Policy"
  policy = jsonencode({
    Version = "2012-10-17"
    "Statement" : [
      {
        Effect : "Allow",
        Resource : [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:dms",
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:dms:*",
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/dms-build",
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/dms-build:*"
        ],
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        Effect : "Allow",
        Resource : [
          "arn:aws:s3:::codepipeline-${var.region}-*"
        ],
        Action : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
      },
      {
        Effect : "Allow",
        Action : [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ],
        Resource : [
          "arn:aws:codebuild:${var.region}:${data.aws_caller_identity.current.account_id}:report-group/dms-build-*"
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "dms-codebuild-attach-inline" {
  role       = aws_iam_role.dms-codebuild-role.name
  policy_arn = aws_iam_policy.code_build_policy.arn
}
resource "aws_iam_role_policy_attachment" "dms-codebuild-attach" {
  role       = aws_iam_role.dms-codebuild-role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}
resource "aws_iam_role" "dms-codebuild-role" {
  name               = "dms-codebuild-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}
resource "aws_codebuild_source_credential" "github" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.GITHUB_TOKEN
}
resource "aws_codebuild_project" "dms" {
  name           = "dms-build"
  badge_enabled  = true
  source_version = "main"
  service_role   = aws_iam_role.dms-codebuild-role.arn
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      type  = "PLAINTEXT"
      value = var.region
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      type  = "PLAINTEXT"
      value = "dms"
    }
    environment_variable {
      name  = "IMAGE_TAG"
      type  = "PLAINTEXT"
      value = "latest"
    }
  }
  artifacts {
    type = "NO_ARTIFACTS"
  }
  logs_config {
    cloudwatch_logs {
      group_name = "dms"
      status     = "ENABLED"
    }
  }
  source {
    type                = "GITHUB"
    location            = var.REPO_URL
    report_build_status = true
    git_clone_depth     = 1

    git_submodules_config {
      fetch_submodules = false
    }
  }
  tags = {
    "project" = "dms"
  }
}
