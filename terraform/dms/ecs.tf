### ECS Cluster ###
resource "aws_ecs_cluster" "dms-ecs-cluster" {
  name = "dms-ecs-cluster"
  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
  ]
  tags = {
    Name    = "DMS"
    project = "dms"
  }
}

resource "aws_security_group" "dms-ecs-sg" {
  name                   = "dms-ecs-sg"
  vpc_id                 = aws_vpc.dms-vpc.id
  revoke_rules_on_delete = false
  description            = "DMS ECS Security Group"
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
    project = "dms"
  }
}
data "aws_ecs_task_definition" "dms-task-def" {
  task_definition = aws_ecs_task_definition.dms-task.family
}
resource "aws_ecs_service" "dms-service" {
  name                              = "dms-service"
  health_check_grace_period_seconds = 0

  cluster                 = aws_ecs_cluster.dms-ecs-cluster.id
  desired_count           = 1
  enable_ecs_managed_tags = true
  launch_type             = "FARGATE"
  platform_version        = "1.4.0"

  tags = {
    project = "dms"
  }

  task_definition = "${aws_ecs_task_definition.dms-task.family}:${max(aws_ecs_task_definition.dms-task.revision, data.aws_ecs_task_definition.dms-task-def.revision)}"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    container_name   = "dms"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.dms-group-service-blue.arn
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.dms-ecs-sg.id]
    subnets          = [aws_subnet.dms-cluster-subnet-blue.id, aws_subnet.dms-cluster-subnet-green.id]
  }
  timeouts {}
}
resource "aws_ecs_task_definition" "dms-task" {
  family                   = "dms-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.execution_role.arn
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_role.arn
  tags = {
    project = "dms"
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
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "dms-ecs"
        }
      },
      "entryPoint": [],
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
      "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/dms:latest",
      "startTimeout": null,
      "firelensConfiguration": null,
      "dependsOn": null,
      "disableNetworking": null,
      "interactive": null,
      "healthCheck": null,
      "essential": true,
      "links": [],
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
resource "aws_iam_role" "execution_role" {
  name               = "dms-execution-role"
  assume_role_policy = data.aws_iam_policy_document.execution_role-policy.json
  description        = "DMS ECS Execution"
  tags = {
    project = "dms"
  }
}
resource "aws_iam_role_policy_attachment" "dms-execution-role-attach" {
  role       = aws_iam_role.task_role.name
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