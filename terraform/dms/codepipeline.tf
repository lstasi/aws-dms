resource "aws_codepipeline" "dms-pipeline" {
  name     = "dms-pipeline"
  role_arn = data.aws_iam_role.dms-codepipeline-role.arn
  tags     = {
    project = "dms"
  }

  artifact_store {
    location = aws_s3_bucket.dms-bucket-deploy.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      category = "Source"
      configuration = {
        "PollForSourceChanges" = "false"
        "S3Bucket"             = "dms-bucket-deploy"
        "S3ObjectKey"          = "dms.zip"
      }
      input_artifacts = []
      name            = "SourceS3"
      output_artifacts = [
        "S3Artifacts",
      ]
      owner     = "AWS"
      provider  = "S3"
      region    = "us-east-1"
      run_order = 1
      version   = "1"
    }
    action {
      category = "Source"
      configuration = {
        "ImageTag"       = "latest"
        "RepositoryName" = "dms"
      }
      input_artifacts = []
      name            = "SourceECR"
      output_artifacts = [
        "ECRArtifact",
      ]
      owner     = "AWS"
      provider  = "ECR"
      region    = "us-east-1"
      run_order = 1
      version   = "1"
    }
  }
  stage {
    name = "Deploy"

    action {
      category = "Deploy"
      configuration = {
        "AppSpecTemplateArtifact"        = "S3Artifacts"
        "AppSpecTemplatePath"            = "appspec.yaml"
        "ApplicationName"                = "dms-app"
        "DeploymentGroupName"            = "dms-app-group"
        "Image1ArtifactName"             = "ECRArtifact"
        "Image1ContainerName"            = "IMAGE1_NAME"
        "TaskDefinitionTemplateArtifact" = "S3Artifacts"
        "TaskDefinitionTemplatePath"     = "taskdef.json"
      }
      input_artifacts = ["S3Artifacts","ECRArtifact"]
      name             = "Deploy"
      output_artifacts = []
      owner            = "AWS"
      provider         = "CodeDeployToECS"
      region           = "us-east-1"
      run_order        = 1
      version          = "1"
    }
  }
}
resource "aws_s3_bucket" "dms-bucket-deploy" {
  bucket        = "dms-bucket-deploy"
  force_destroy = true
  request_payer = "BucketOwner"
  acl           = "private"
  tags = {
    "project" = "dms"
  }
  versioning {
    enabled    = true
    mfa_delete = false
  }
}
data "archive_file" "dms-zip" {
  type        = "zip"
  source_dir  = "deploy"
  output_path = "dms.zip"
}
resource "aws_s3_bucket_object" "dms-zip" {
  bucket = aws_s3_bucket.dms-bucket-deploy.bucket
  key    = "dms.zip"
  source = "dms.zip"
}