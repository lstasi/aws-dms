### Code Deploy ###
data "aws_iam_policy_document" "dms-code-deploy" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy_attachment" "dms-code-deploy-attach" {
  role       = aws_iam_role.dms-code-deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
resource "aws_iam_role" "dms-code-deploy" {
  name               = "dms-code-deploy"
  assume_role_policy = data.aws_iam_policy_document.dms-code-deploy.json
  description        = "DMS code deploy"
  tags = {
    project = "dms"
  }
}