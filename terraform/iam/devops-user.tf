resource "aws_iam_user" "devops-user" {
  name = "devops-user"
  path = "/"

  tags = {
    project = "dms"
  }
}

resource "aws_iam_access_key" "devops-user" {
  user    = aws_iam_user.devops-user.name
}

resource "aws_iam_policy" "dms-policy" {
  name        = "dms-policy"
  description = "DMS policy"
  tags = {
    project = "dms"
  }
  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
      {
          "Effect": "Allow",
          "Action": "*",
          "Resource": "*"
      }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "policy-attach-devops-user" {
  name       = "policy-attach-dms"
  users = [aws_iam_user.devops-user.name]
  policy_arn = aws_iam_policy.dms-policy.arn
}

output "credentials" {
  value = "export AWS_ACCESS_KEY_ID=${aws_iam_access_key.devops-user.id}\nexport AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.devops-user.secret}\nexport AWS_DEFAULT_REGION=${var.region}"
}
