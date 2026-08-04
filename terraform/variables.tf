# Terraform Variables Configuration for SecDO Infrastructure

variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name prefix for tags and resources"
  type        = string
  default     = "secdo"
}

variable "ami_id" {
  description = "Ubuntu 24.04 LTS AMI ID (default for us-east-1)"
  type        = string
  default     = "ami-0e86e20dae9224db8" # Ubuntu 24.04 LTS AMI ID
}

variable "jenkins_instance_type" {
  description = "Instance size for Jenkins CI/CD & SonarQube server"
  type        = string
  default     = "t3.medium"
}

variable "app_instance_type" {
  description = "Instance size for Application & Monitoring deployment server"
  type        = string
  default     = "t3.small"
}

variable "ecr_repo_name" {
  description = "AWS ECR repository name"
  type        = string
  default     = "secdo-app-repo"
}

variable "ssh_key_name" {
  description = "AWS EC2 Key pair name for SSH access"
  type        = string
  default     = "SecDO"
}
