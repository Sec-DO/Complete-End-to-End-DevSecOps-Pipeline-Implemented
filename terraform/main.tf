# Main Terraform Infrastructure Provisioning File (Mumbai ap-south-1 Region)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Dynamic Canonical Ubuntu 24.04 LTS AMI Lookup for ap-south-1
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 1. AWS ECR Repository Creation
resource "aws_ecr_repository" "secdo_ecr" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = var.ecr_repo_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# ECR Lifecycle Policy (Retain last 10 images)
resource "aws_ecr_lifecycle_policy" "secdo_ecr_policy" {
  repository = aws_ecr_repository.secdo_ecr.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain last 10 tagged container images"
        selection = {
          tagStatus     = "any"
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# 2. Jenkins CI/CD EC2 Instance (Placed in Private Subnet 1a - Mumbai Region)
resource "aws_instance" "jenkins_server" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type               = var.jenkins_instance_type
  key_name                    = var.ssh_key_name
  subnet_id                   = aws_subnet.private_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins_instance_profile.name
  associate_public_ip_address = false

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = file("${path.module}/../scripts/setup-jenkins-server.sh")

  tags = {
    Name        = "${var.project_name}-jenkins-server"
    Role        = "CI/CD & SAST Engine"
    Subnet      = "Private Subnet 1a"
    Region      = var.aws_region
    Environment = var.environment
  }
}

# 3. Application Deployment EC2 Instance (Placed in Private Subnet 1b - Mumbai Region)
resource "aws_instance" "app_server" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type               = var.app_instance_type
  key_name                    = var.ssh_key_name
  subnet_id                   = aws_subnet.private_subnet_2.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = false

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = file("${path.module}/../scripts/setup-app-server.sh")

  tags = {
    Name        = "${var.project_name}-app-server"
    Role        = "Production Application Host"
    Subnet      = "Private Subnet 1b"
    Region      = var.aws_region
    Environment = var.environment
  }
}
