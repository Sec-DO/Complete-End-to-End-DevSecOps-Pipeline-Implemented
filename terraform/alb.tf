# Public AWS Application Load Balancer (ALB) to expose Private Subnet Services to Browser securely

# 1. ALB Security Group in Public Subnet
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security Group for Public Application Load Balancer"
  vpc_id      = aws_vpc.secdo_vpc.id

  # Inbound Ports for Browser Access
  ingress {
    description = "Application HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Web Console"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube Web Console"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana Observability Dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus Metrics UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}

# 2. Application Load Balancer Resource
resource "aws_lb" "secdo_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

# -------------------------------------------------------------------
# Target Groups for Private Subnet Instances
# -------------------------------------------------------------------

# Target Group: Application (Port 80)
resource "aws_lb_target_group" "app_tg" {
  name        = "${var.project_name}-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.secdo_vpc.id
  target_type = "instance"

  health_check {
    path                = "/health.php"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "app_tg_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server.id
  port             = 80
}

# Target Group: Jenkins (Port 8080)
resource "aws_lb_target_group" "jenkins_tg" {
  name        = "${var.project_name}-jenkins-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.secdo_vpc.id
  target_type = "instance"

  health_check {
    path                = "/login"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200,403"
  }
}

resource "aws_lb_target_group_attachment" "jenkins_tg_attach" {
  target_group_arn = aws_lb_target_group.jenkins_tg.arn
  target_id        = aws_instance.jenkins_server.id
  port             = 8080
}

# Target Group: SonarQube (Port 9000)
resource "aws_lb_target_group" "sonarqube_tg" {
  name        = "${var.project_name}-sonarqube-tg"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.secdo_vpc.id
  target_type = "instance"

  health_check {
    path                = "/api/system/status"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "sonarqube_tg_attach" {
  target_group_arn = aws_lb_target_group.sonarqube_tg.arn
  target_id        = aws_instance.jenkins_server.id
  port             = 9000
}

# Target Group: Grafana (Port 3000)
resource "aws_lb_target_group" "grafana_tg" {
  name        = "${var.project_name}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.secdo_vpc.id
  target_type = "instance"

  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "grafana_tg_attach" {
  target_group_arn = aws_lb_target_group.grafana_tg.arn
  target_id        = aws_instance.app_server.id
  port             = 3000
}

# Target Group: Prometheus (Port 9090)
resource "aws_lb_target_group" "prometheus_tg" {
  name        = "${var.project_name}-prometheus-tg"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = aws_vpc.secdo_vpc.id
  target_type = "instance"

  health_check {
    path                = "/-/healthy"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "prometheus_tg_attach" {
  target_group_arn = aws_lb_target_group.prometheus_tg.arn
  target_id        = aws_instance.app_server.id
  port             = 9090
}

# -------------------------------------------------------------------
# ALB Listeners
# -------------------------------------------------------------------

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.secdo_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_listener" "jenkins_listener" {
  load_balancer_arn = aws_lb.secdo_alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_tg.arn
  }
}

resource "aws_lb_listener" "sonarqube_listener" {
  load_balancer_arn = aws_lb.secdo_alb.arn
  port              = "9000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonarqube_tg.arn
  }
}

resource "aws_lb_listener" "grafana_listener" {
  load_balancer_arn = aws_lb.secdo_alb.arn
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}

resource "aws_lb_listener" "prometheus_listener" {
  load_balancer_arn = aws_lb.secdo_alb.arn
  port              = "9090"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus_tg.arn
  }
}
