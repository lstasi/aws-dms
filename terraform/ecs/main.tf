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
data "aws_caller_identity" "current" {}


### Network ###
resource "aws_vpc" "dms-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "project" = "dms"
  }
}

resource "aws_vpc_dhcp_options" "default" {
  domain_name         = "ec2.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags = {
    "project" = "dms"
  }
}
resource "aws_network_acl" "default" {
  vpc_id = aws_vpc.dms-vpc.id
  egress {
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = ""
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }
  ingress {
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
    icmp_code       = 0
    icmp_type       = 0
    ipv6_cidr_block = ""
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }
  tags = {
    "project" = "dms"
  }
}

resource "aws_internet_gateway" "dms-igw" {
  vpc_id = aws_vpc.dms-vpc.id
  tags = {
    "project" = "dms"
  }
}
resource "aws_subnet" "dms-cluster-subnet1" {
  vpc_id     = aws_vpc.dms-vpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    "project" = "dms"
  }
}

resource "aws_subnet" "dms-cluster-subnet2" {
  vpc_id     = aws_vpc.dms-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    "project" = "dms"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.dms-vpc.id
  tags = {
    "project" = "dms"
  }
}
resource "aws_route_table" "sec" {
  vpc_id = aws_vpc.dms-vpc.id
  tags = {
    "project" = "dms"
  }
}
resource "aws_route_table_association" "main_assoc" {
  subnet_id      = aws_subnet.dms-cluster-subnet1.id
  route_table_id = aws_route_table.sec.id
}

resource "aws_route_table_association" "sec_assoc" {
  subnet_id      = aws_subnet.dms-cluster-subnet2.id
  route_table_id = aws_route_table.sec.id
}

### LB ###
resource "aws_lb" "dms-lb" {
  name               = "dms-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.dms-cluster-subnet1.id, aws_subnet.dms-cluster-subnet2.id]
  tags = {
    "project" = "dms"
  }
}
resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.dms-lb.arn
  port              = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dms-group-service-1.arn
  }

}
resource "aws_lb_target_group" "dms-group-service-1" {
  name        = "dms-service-1"
  vpc_id      = aws_vpc.dms-vpc.id
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = "5"
    port                = "8080"
    path                = "/probe"
    protocol            = "HTTP"
    interval            = 30
    matcher             = "200"
  }
  tags = {
    "project" = "dms"
  }
}

resource "aws_lb_target_group" "dms-group-service-2" {
  name        = "dms-service-2"
  vpc_id      = aws_vpc.dms-vpc.id
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = "5"
    port                = "8080"
    path                = "/probe"
    protocol            = "HTTP"
    interval            = 30
    matcher             = "200"
  }
  tags = {
    "project" = "dms"
  }
}
resource "aws_security_group" "dms-lb-sg" {
  name                   = "dms-lb-sg"
  vpc_id                 = aws_vpc.dms-vpc.id
  revoke_rules_on_delete = false
  description            = "DMS LB Security Group"
  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 80
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 80
  }
  egress {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }
  tags = {
    "project" = "dms"
  }
}


### ECS Cluster ###
resource "aws_ecs_cluster" "dms-cluster" {
  name = "dms-cluster"
  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
  ]
  tags = {
    "project" = "dms"
  }
}

resource "aws_security_group" "dms-ecs-sg" {
  name                   = "dms-ecs-sg"
  vpc_id                 = aws_vpc.dms-vpc.id
  revoke_rules_on_delete = false
  description            = "2021-04-25T15:55:31.207Z"
  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 8080
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 8080
  }
  egress {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }
  tags = {
    "project" = "dms"
  }
}
data "aws_ecs_task_definition" "dms-task-def" {
  task_definition = aws_ecs_task_definition.dms-task.family
}
resource "aws_ecs_service" "dms-service" {
  name                              = "dms-service"
  health_check_grace_period_seconds = 0

  cluster                 = aws_ecs_cluster.dms-cluster.id
  desired_count           = 1
  enable_ecs_managed_tags = true
  launch_type             = "FARGATE"
  platform_version        = "1.4.0"

  tags = {
    "project" = "dms"
  }

  task_definition = "${aws_ecs_task_definition.dms-task.family}:${max(aws_ecs_task_definition.dms-task.revision, data.aws_ecs_task_definition.dms-task-def.revision)}"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    container_name   = "dms"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.dms-group-service-1.arn
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.dms-ecs-sg.id]
    subnets          = [aws_subnet.dms-cluster-subnet1.id, aws_subnet.dms-cluster-subnet2.id]
  }
  timeouts {}
}
resource "aws_ecs_task_definition" "dms-task" {
  family                   = "dms-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.execution_role_arn.arn
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_role_arn.arn
  tags = {
    "project" = "dms"
  }
  container_definitions = <<TASK_DEFINITION
[
    {
      "dnsSearchDomains": null,
      "environmentFiles": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": null,
        "options": {
          "awslogs-group": "/ecs/dms-task",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "entryPoint": null,
      "portMappings": [
        {
          "hostPort": 8080,
          "protocol": "tcp",
          "containerPort": 8080
        }
      ],
      "command": null,
      "linuxParameters": null,
      "cpu": 0,
      "environment": [],
      "resourceRequirements": null,
      "ulimits": null,
      "dnsServers": null,
      "mountPoints": [],
      "workingDirectory": null,
      "secrets": null,
      "dockerSecurityOptions": null,
      "memory": null,
      "memoryReservation": null,
      "volumesFrom": [],
      "stopTimeout": null,
      "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/dms:latest",
      "startTimeout": null,
      "firelensConfiguration": null,
      "dependsOn": null,
      "disableNetworking": null,
      "interactive": null,
      "healthCheck": null,
      "essential": true,
      "links": null,
      "hostname": null,
      "extraHosts": null,
      "pseudoTerminal": null,
      "user": null,
      "readonlyRootFilesystem": null,
      "dockerLabels": null,
      "systemControls": null,
      "privileged": null,
      "name": "dms"
    }
]
TASK_DEFINITION
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
resource "aws_iam_role" "execution_role_arn" {
  name = "dms execution role"
  assume_role_policy = data.aws_iam_policy_document.execution_role-policy.json
  description        = "dms ecs execution"
  tags = {
    "project" = "dms"
  }
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
resource "aws_iam_role" "task_role_arn" {
  name = "dms execution role"
  assume_role_policy = data.aws_iam_policy_document.task_role-policy.json
  description        = "dms ecs tasks"
  tags = {
    "project" = "dms"
  }
}

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
resource "aws_iam_role" "dms-code-deploy" {
  name               = "dms-code-deploy"
  assume_role_policy = data.aws_iam_policy_document.dms-code-deploy.json
  description        = "dms code deploy"
  tags = {
    "project" = "dms"
  }
}
resource "aws_codedeploy_app" "dms-app" {
  name             = "dms-app"
  compute_platform = "ECS"
  tags             = {}
}
resource "aws_codedeploy_deployment_group" "dms-app-group" {
  deployment_group_name  = "dms-app-group"
  app_name               = "dms-app"
  service_role_arn       = aws_iam_role.dms-code-deploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  tags = {
    "project" = "dms"
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
    cluster_name = "dms-cluster"
    service_name = "dms-service"
  }
  load_balancer_info {

    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
          aws_lb_listener.http_80.arn,
        ]
      }
      target_group {
        name = "dms-service-1"
      }
      target_group {
        name = "dms-service-2"
      }
    }
  }
}

output "lb-dns" {
  value = aws_lb.dms-lb.dns_name
}