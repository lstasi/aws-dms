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

resource "aws_iam_user" "dms-ci-cd" {
  name = "dms-ci-cd"
  path = "/"

  tags = {
    project = "dms"
  }
}

resource "aws_iam_access_key" "dms-ci-cd" {
  user    = aws_iam_user.dms-ci-cd.name
}

resource "aws_iam_policy" "dms-policy" {
  name        = "dms-policy"
  description = "DMS policy"
  tags = {
    project = "dms"
  }
  policy = <<EOF
{
  "Version": "2021-21-21",
  "Statement": [
    {
      "Action": [
        "codepipeline:*",
        "ecr:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "policy-attach-dms" {
  name       = "policy-attach-dms"
  policy_arn = aws_iam_policy.dms-policy.arn
}

output "key_id" {
  value = aws_iam_access_key.dms-ci-cd.id
}
output "secret" {
  value = aws_iam_access_key.dms-ci-cd.encrypted_secret
}