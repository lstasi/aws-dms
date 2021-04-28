terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "dms" {
  name                 = "dms"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_iam_policy" "codebuild-dms-service-role-policy" {
  description = "DMS Policy used in trust relationship with CodeBuild"
  path                = "/service-role/"
  policy      = jsonencode(
          {
               Statement = [
                   {
                       Action   = [
                           "logs:CreateLogGroup",
                           "logs:CreateLogStream",
                           "logs:PutLogEvents",


                        ]
                     Effect   = "Allow"
                       Resource = [
                           "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/dms",
                           "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/dms:*",
                        ]
                        # (1 unchanged element hidden)
                    },
                   {
                       Action   = [
                           "s3:PutObject",
                           "s3:GetObject",
                           "s3:GetObjectVersion",
                           "s3:GetBucketAcl",
                           "s3:GetBucketLocation",
                        ]
                       Effect   = "Allow"
                       Resource = [
                           "arn:aws:s3:::codepipeline-us-east-1-*",
                        ]
                    },
                   {
                       Action   = [
                           "codebuild:CreateReportGroup",
                           "codebuild:CreateReport",
                           "codebuild:UpdateReport",
                           "codebuild:BatchPutTestCases",
                           "codebuild:BatchPutCodeCoverages",
                        ]
                       Effect   = "Allow"
                       Resource = [
                           "arn:aws:codebuild:us-east-1:${data.aws_caller_identity.current.account_id}:report-group/dms-*",
                        ]
                    },
                ]
               Version   = "2012-10-17"
            })

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
resource "aws_iam_role" "codebuild-dms-service-role" {
  name                = "codebuild-dms-service-role"
  path                = "/service-role/"
  assume_role_policy  = data.aws_iam_policy_document.instance-assume-role-policy.json # (not shown)
  managed_policy_arns = [aws_iam_policy.codebuild-dms-service-role-policy.arn]

}

resource "aws_codebuild_project" "dms" {
  name         = "dms"
  badge_enabled = true
  source_version = "main"
  service_role = aws_iam_role.codebuild-dms-service-role.arn
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

  }
  artifacts {
    type = "NO_ARTIFACTS"
  }
  logs_config {
    cloudwatch_logs {
      status = "DISABLED"
    }
  }
  source {
    type            = "GITHUB"
    location        = "https://github.com/lstasi/aws-dms.git"
    report_build_status = true
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = false
    }
  }
  tags = {
    "project" = "dms"
  }
}
