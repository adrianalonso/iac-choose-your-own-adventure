# Network
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

# security group
resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.main.id

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

resource "aws_security_group" "ecs_service" {
  vpc_id = aws_vpc.main.id

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

# Application Load Balancer
resource "aws_lb" "loadbalancer" {
  name               = "loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# ECR Repository
resource "aws_ecr_repository" "repo" {
  name                 = "repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}


# ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = "cluster"
}

# Fargate Task Definition

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/service"
  retention_in_days = 7

}

resource "aws_ecs_task_definition" "task_definition" {
  family = "service"
  container_definitions = jsonencode([{
    name      = "awsx-ecs"
    image     = "${aws_ecr_repository.repo.repository_url}:latest"
    cpu       = 128
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/service"
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
    subnets          = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
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


data "local_file" "dockerfile" {
  filename = "${path.module}/app/Dockerfile"
}

locals {
  dockerfile_hash = sha256(file("${path.module}/app/Dockerfile"))
}

resource "null_resource" "docker_build_and_push" {
  provisioner "local-exec" {
    command = <<EOT
      # Autenticarse con ECR
      aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.repo.repository_url}
      
      # Construir la imagen Docker
      docker build --platform linux/amd64 -t ${aws_ecr_repository.repo.repository_url}:latest ./app
      
      # Etiquetar la imagen
      docker tag ${aws_ecr_repository.repo.repository_url}:latest ${aws_ecr_repository.repo.repository_url}:latest
      
      # Subir la imagen a ECR
      docker push ${aws_ecr_repository.repo.repository_url}:latest
    EOT
  }
  triggers = {
    dockerfile_hash = local.dockerfile_hash
  }
  depends_on = [aws_ecr_repository.repo]
}

# Output the Load Balancer DNS name
output "frontendURL" {
  value = aws_lb.loadbalancer.dns_name
}

output "repository_url" {
  value = aws_ecr_repository.repo.repository_url
}
