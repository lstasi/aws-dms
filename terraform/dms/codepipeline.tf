resource "aws_codepipeline" "dms-pipeline" {
  name     = "dms-pipeline"
  role_arn = aws_iam_role.dms-codepipeline-role.arn
  tags     = {}

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
      input_artifacts = [
        "S3Artifacts",
        "ECRArtifact",
      ]
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
data "aws_iam_policy_document" "code_pipeline-instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}
resource "aws_iam_policy" "code_pipeline_policy" {
  name        = "code_pipeline_policy"
  path        = "/"
  description = "DMS Code Pipeline Policy"
  policy = jsonencode({
    "Statement" : [
      {
        Action : [
          "iam:PassRole"
        ],
        Resource : "*",
        Effect : "Allow",
        Condition : {
          "StringEqualsIfExists" : {
            "iam:PassedToService" : [
              "cloudformation.amazonaws.com",
              "elasticbeanstalk.amazonaws.com",
              "ec2.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      },
      {
        Action : [
          "codecommit:CancelUploadArchive",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive"
        ],
        Resource : "*",
        Effect : "Allow"
      },
      {
        Action : [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ],
        Resource : "*",
        Effect : "Allow"
      },
      {
        Action : [
          "codestar-connections:UseConnection"
        ],
        Resource : "*",
        Effect : "Allow"
      },
      {
        Action : [
          "elasticbeanstalk:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "s3:*",
          "sns:*",
          "cloudformation:*",
          "rds:*",
          "sqs:*",
          "ecs:*"
        ],
        Resource : "*",
        Effect : "Allow"
      },
      {
        Action : [
          "lambda:InvokeFunction",
          "lambda:ListFunctions"
        ],
        Resource : "*",
        Effect : "Allow"
      },
      {
        Action : [
          "opsworks:CreateDeployment",
          "opsworks:DescribeApps",
          "opsworks:DescribeCommands",
          "opsworks:DescribeDeployments",
          "opsworks:DescribeInstances",
          "opsworks:DescribeStacks",
          "opsworks:UpdateApp",
          "opsworks:UpdateStack"
        ],
        Resource : "*",
        Effect : "Allow"
      },
      {
        Action : [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:SetStackPolicy",
          "cloudformation:ValidateTemplate"
        ],
        Resource : "*",
        Effect : "Allow"
      },
      {
        Action : [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ],
        Resource : "*",
        Effect : "Allow"
      },
      {
        Effect : "Allow",
        Action : [
          "devicefarm:ListProjects",
          "devicefarm:ListDevicePools",
          "devicefarm:GetRun",
          "devicefarm:GetUpload",
          "devicefarm:CreateUpload",
          "devicefarm:ScheduleRun"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "servicecatalog:ListProvisioningArtifacts",
          "servicecatalog:CreateProvisioningArtifact",
          "servicecatalog:DescribeProvisioningArtifact",
          "servicecatalog:DeleteProvisioningArtifact",
          "servicecatalog:UpdateProduct"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "cloudformation:ValidateTemplate"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "ecr:DescribeImages"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "states:DescribeExecution",
          "states:DescribeStateMachine",
          "states:StartExecution"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "appconfig:StartDeployment",
          "appconfig:StopDeployment",
          "appconfig:GetDeployment"
        ],
        Resource : "*"
      }
    ],
    "Version" : "2012-10-17"
  })
}
resource "aws_iam_role_policy_attachment" "dms-codepipeline-attach-inline" {
  role       = aws_iam_role.dms-codepipeline-role.name
  policy_arn = aws_iam_policy.code_pipeline_policy.arn
}
resource "aws_iam_role_policy_attachment" "dms-codepipeline-attach" {
  role       = aws_iam_role.dms-codepipeline-role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}
resource "aws_iam_role" "dms-codepipeline-role" {
  name               = "dms-codepipeline-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.code_pipeline-instance-assume-role-policy.json
}