### Code Build ###
resource "aws_codebuild_source_credential" "github" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.GITHUB_TOKEN
}
resource "aws_codebuild_project" "dms" {
  name           = "dms-build"
  badge_enabled  = true
  source_version = "main"
  service_role   = data.aws_iam_role.dms-codebuild-role.arn
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
resource "aws_codebuild_webhook" "dms-webhook" {
  project_name = aws_codebuild_project.dms.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "main"
    }
  }
}