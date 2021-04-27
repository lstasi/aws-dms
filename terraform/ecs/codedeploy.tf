### Deploy Pipeline ###
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
resource "aws_codedeploy_app" "dms-app" {
  name             = "dms-app"
  compute_platform = "ECS"
  tags = {
    project = "dms"
  }
}
resource "aws_codedeploy_deployment_group" "dms-app-group" {
  deployment_group_name  = "dms-app-group"
  app_name               = aws_codedeploy_app.dms-app.name
  service_role_arn       = aws_iam_role.dms-code-deploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  tags = {
    project = "dms"
  }
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }
  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE",
      "DEPLOYMENT_STOP_ON_REQUEST",
    ]
  }
  ecs_service {
    cluster_name = aws_ecs_cluster.dms-ecs-cluster.name
    service_name = aws_ecs_service.dms-service.name
  }
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
          aws_lb_listener.http_80.arn,
        ]
      }
      target_group {
        name = aws_lb_target_group.dms-group-service-blue.name
      }
      target_group {
        name = aws_lb_target_group.dms-group-service-green.name
      }
    }
  }
}