# Gather Data
data "aws_vpc" "vpc" {
  tags = {
    Name = "${var.vpc_name}"
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Name = var.app_subnet_name
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Name = var.app_public_subnet_name
  }
}

data "aws_security_group" "office_sg" {
  id = var.load_balancer_sg
}

data "aws_ecs_cluster" "cluster_id" {
  cluster_name = "${var.cluster_name}"
}

# General resources 
resource "aws_ecr_repository" "kepler" {
  name = "kepler"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment        = upper(var.kepler_env)
    Project            = "DASHBOARD"
    Department         = "DATAENGINEERING"
    Owner              = "TOM@7PARKDATA.COM"
    BusinessLine       = "CRE"
    FinancialReporting = "GANDA"
    Name               = "kepler-tableau"
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/apps/kepler-ecs-${var.kepler_env}"

  tags = {
    Environment        = upper(var.kepler_env)
    Project            = "DASHBOARD"
    Department         = "DATAENGINEERING"
    Owner              = "TOM@7PARKDATA.COM"
    BusinessLine       = "CRE"
    FinancialReporting = "GANDA"
    Name               = "/apps/kepler-ecs-${var.kepler_env}"
  }
}

# kepler Service
# Role for ECS kepler
resource "aws_iam_role" "kepler_ecs_role" {
  name = "7p-kepler-${var.kepler_env}-ecs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "container_access" {
  role       = aws_iam_role.kepler_ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "logs_access" {
  role       = aws_iam_role.kepler_ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.kepler_ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# kepler Load Balancers
module "kepler-lb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.6"

  name = var.kepler_lb_name

  load_balancer_type = "application"
  internal           = false

  vpc_id          = data.aws_vpc.vpc.id
  subnets         = flatten([data.aws_subnet_ids.public.ids])
  security_groups = [data.aws_security_group.office_sg.id]

  target_groups = [
    {
      name             = var.kepler_tg_name
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      health_check = {
        enabled             = true
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 5
        unhealthy_threshold = 10
        timeout             = 30
        interval            = 60
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.kepler_certificate_arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      action_type        = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  tags = {
    Environment        = upper(var.kepler_env)
    Project            = "DASHBOARD"
    Department         = "DATAENGINEERING"
    Owner              = "TOM@7PARKDATA.COM"
    BusinessLine       = "CRE"
    FinancialReporting = "GANDA"
    Name               = "/apps/kepler-ecs-${var.kepler_env}"
  }
}

module "kepler-sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "7p-kepler-${var.kepler_env}-ecs"
  description = "Access to kepler-${var.kepler_env}-service ECS"
  vpc_id      = data.aws_vpc.vpc.id
  ingress_with_source_security_group_id = [
    {
      from_port                = var.kepler_port
      to_port                  = var.kepler_port
      protocol                 = "tcp"
      description              = "Access to ecs kepler from load balancer"
      source_security_group_id = data.aws_security_group.office_sg.id
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}

resource "aws_ecs_task_definition" "kepler_td" {
  family = "kepler-${var.kepler_env}-td"
  container_definitions = templatefile("./task_def.tmpl", {
    kepler_env    = var.kepler_env,
    kepler_branch = var.kepler_branch,
    ecs_role      = aws_iam_role.kepler_ecs_role.arn,
    kepler_port   = var.kepler_port
    kepler_memory = var.kepler_memory
    kepler_cpu    = var.kepler_cpu
    commit_id     = var.CI_COMMIT_ID
  })
  network_mode             = "awsvpc"
  cpu                      = var.kepler_cpu
  memory                   = var.kepler_memory
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.kepler_ecs_role.arn
  execution_role_arn       = aws_iam_role.kepler_ecs_role.arn

  tags = {
    Environment        = upper(var.kepler_env)
    Project            = "DASHBOARD"
    Department         = "DATAENGINEERING"
    Owner              = "TOM@7PARKDATA.COM"
    BusinessLine       = "CRE"
    FinancialReporting = "GANDA"
    Name               = "/apps/kepler-ecs-${var.kepler_env}"
  }
}

resource "aws_ecs_service" "kepler_service" {
  name                               = "kepler-${var.kepler_env}-service"
  cluster                            = data.aws_ecs_cluster.cluster_id.id
  task_definition                    = aws_ecs_task_definition.kepler_td.arn
  desired_count                      = var.task_count
  launch_type                        = "FARGATE"
  enable_ecs_managed_tags            = true
  propagate_tags                     = "SERVICE"
  deployment_minimum_healthy_percent = 50

  load_balancer {
    target_group_arn = module.kepler-lb.target_group_arns[0]
    container_name   = "kepler_${var.kepler_env}"
    container_port   = var.kepler_port
  }

  network_configuration {
    subnets          = flatten([data.aws_subnet_ids.private.ids])
    security_groups  = [module.kepler-sg.this_security_group_id]
    assign_public_ip = false
  }

  tags = {
    Environment        = upper(var.kepler_env)
    Project            = "DASHBOARD"
    Department         = "DATAENGINEERING"
    Owner              = "TOM@7PARKDATA.COM"
    BusinessLine       = "CRE"
    FinancialReporting = "GANDA"
    Name               = "/apps/kepler-ecs-${var.kepler_env}"
  }
}
