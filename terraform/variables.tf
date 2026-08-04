# Terraform Variables Configuration for SecDO Infrastructure (Mumbai ap-south-1)

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
  description = "Optional custom AMI ID override. Defaults to dynamic Canonical Ubuntu 24.04 LTS lookup."
  type        = string
  default     = ""
}

variable "bastion_instance_type" {
  description = "Instance size for Public Bastion SSH Jump Host (Free-Tier eligible)"
  type        = string
  default     = "t3.micro"
}

variable "jenkins_instance_type" {
  description = "Instance size for Jenkins CI/CD & SonarQube SAST Server"
  type        = string
  default     = "t3.medium"
}

variable "app_instance_type" {
  description = "Instance size for Application Docker Swarm & Monitoring Server"
  type        = string
  default     = "t3.small"
}

variable "ecr_repo_name" {
  description = "AWS ECR repository name"
  type        = string
  default     = "secdo-ecr"
}

variable "ssh_key_name" {
  description = "AWS EC2 Key pair name for SSH access"
  type        = string
  default     = "SecDO"
}
