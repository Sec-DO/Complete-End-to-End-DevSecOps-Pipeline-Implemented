# Default Terraform Configuration Values for SecDO (Mumbai Region)
aws_region            = "ap-south-1"
environment           = "production"
project_name          = "secdo"
jenkins_instance_type = "t3.medium"
app_instance_type     = "t3.small"
ecr_repo_name         = "secdo-ecr" # Configured to match 325698037625.dkr.ecr.ap-south-1.amazonaws.com/secdo-ecr
ssh_key_name          = "SecDO"
