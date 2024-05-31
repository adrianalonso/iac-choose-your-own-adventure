resource "aws_ecs_cluster" "cluster" {
  name     = "${var.project_name}-cluster"
  tags_all = var.tags
}


resource "aws_cloudwatch_log_group" "log_group" {
  name              = var.cloudwatch_group
  retention_in_days = 7

}


resource "aws_security_group" "ecs_service" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_ecs_task_definition" "task_definition" {
  family = "service"
  container_definitions = jsonencode([{
    name      = "awsx-ecs"
    image     = var.docker_image
    cpu       = var.container_cpu
    memory    = var.container_memory
    essential = true
    portMappings = [{
      containerPort = 80
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.cloudwatch_group
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  cpu                      = "256"
  memory                   = "512"
}

# Permisos para los Logs de CloudWatch
resource "aws_iam_role_policy_attachment" "execution_role_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}


# Fargate Service
resource "aws_ecs_service" "service" {
  name            = "service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    subnets          = var.subnets
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = var.load_balancer_target_group_arn
    container_name   = "awsx-ecs"
    container_port   = 80
  }
}


resource "aws_iam_role" "execution_role" {
  name = "execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_iam_role" "task_role" {
  name = "task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}
