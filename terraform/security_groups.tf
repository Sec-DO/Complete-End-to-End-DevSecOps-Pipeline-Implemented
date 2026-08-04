# AWS Security Groups Configuration for Bastion, ALB, Jenkins, and App Instances

# 1. Jenkins Security Group (Private Subnet 1a)
resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Security Group for Jenkins CI/CD and SonarQube Server in Private Subnet"
  vpc_id      = aws_vpc.secdo_vpc.id

  # Inbound SSH ONLY from Bastion Host Security Group
  ingress {
    description     = "SSH Access from Bastion Host Only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Jenkins Web UI from ALB or VPC Internal
  ingress {
    description     = "Jenkins Web Interface from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # SonarQube Web UI from ALB
  ingress {
    description     = "SonarQube Web Interface from ALB"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow Internal Communication within VPC
  ingress {
    description = "Internal VPC Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Outbound via NAT Gateway
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-jenkins-sg"
    Environment = var.environment
  }
}

# 2. Application & Monitoring Security Group (Private Subnet 1b)
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Security Group for Application Deployment and Monitoring Stack in Private Subnet"
  vpc_id      = aws_vpc.secdo_vpc.id

  # Inbound SSH ONLY from Bastion Host Security Group and Jenkins SG
  ingress {
    description     = "SSH Access from Bastion & Jenkins SGs"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id, aws_security_group.jenkins_sg.id]
  }

  # Application Web HTTP from ALB
  ingress {
    description     = "Application HTTP Interface from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Grafana Dashboard UI from ALB
  ingress {
    description     = "Grafana Observability Dashboard from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Prometheus Metrics UI from ALB
  ingress {
    description     = "Prometheus Metrics UI from ALB"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow Internal Communication within VPC
  ingress {
    description = "Internal VPC Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Outbound via NAT Gateway
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-app-sg"
    Environment = var.environment
  }
}
