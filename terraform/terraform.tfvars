# Default Terraform Configuration Values for SecDO (Mumbai Region)
aws_region            = "ap-south-1"
environment           = "production"
project_name          = "secdo"
bastion_instance_type = "t3.micro"
jenkins_instance_type = "m7i-flex.large" # 2 vCPU, 8 GiB RAM (High performance for Jenkins & SonarQube)
app_instance_type     = "m7i-flex.large" # 2 vCPU, 8 GiB RAM (High performance for App Swarm & Monitoring)
ecr_repo_name         = "secdo-ecr"
ssh_key_name          = "SecDO"
