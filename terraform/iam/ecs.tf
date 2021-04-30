resource "aws_iam_role" "execution_role" {
  name               = "dms-execution-role"
  assume_role_policy = data.aws_iam_policy_document.execution_role-policy.json
  description        = "DMS ECS Execution"
  tags = {
    project = "dms"
  }
}
data "aws_iam_policy_document" "execution_role-policy" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy_attachment" "dms-execution-role-attach" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
data "aws_iam_policy_document" "task_role-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "task_role" {
  name               = "dms-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_role-policy.json
  description        = "DMS ECS Task"
  tags = {
    project = "dms"
  }
}
resource "aws_iam_role_policy_attachment" "dms-task-role-attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}
resource "aws_iam_role_policy_attachment" "dms-task-role-attach-dynamo" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}
