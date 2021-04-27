### LB ###
resource "aws_lb" "dms-lb" {
  name               = "dms-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dms-lb-sg.id]
  subnets            = [aws_subnet.dms-cluster-subnet-blue.id, aws_subnet.dms-cluster-subnet-green.id]
  tags = {
    Name    = "DMS"
    project = "dms"
  }
}
resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.dms-lb.arn
  port              = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dms-group-service-blue.arn
  }
}
resource "aws_lb_target_group" "dms-group-service-blue" {
  name        = "dms-service-blue"
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
    project = "dms"
  }
}
resource "aws_lb_target_group" "dms-group-service-green" {
  name        = "dms-service-green"
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
    project = "dms"
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
    project = "dms"
  }
}