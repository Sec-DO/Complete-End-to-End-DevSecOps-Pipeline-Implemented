# Terraform Variables Configuration for SecDO Infrastructure (Mumbai Region)

variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "ap-south-1" # Mumbai Region
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
  description = "Ubuntu 24.04 LTS AMI ID for ap-south-1 (Optional override, dynamic lookup enabled)"
  type        = string
  default     = ""
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
