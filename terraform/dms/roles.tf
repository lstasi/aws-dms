data "aws_iam_role" "dms-codebuild-role" {
  name = "dms-codebuild-role"
}
data "aws_iam_role" "dms-code-deploy" {
  name = "dms-code-deploy"
}
data "aws_iam_role" "dms-codepipeline-role" {
  name = "dms-codepipeline-role"
}
data "aws_iam_role" "dms-task-role" {
  name = "dms-task-role"
}
data "aws_iam_role" "dms-execution-role" {
  name = "dms-execution-role"
}