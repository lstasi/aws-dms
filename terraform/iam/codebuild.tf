### Code Build ###
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