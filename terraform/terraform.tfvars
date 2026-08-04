# Default Terraform Configuration Values for SecDO
aws_region            = "us-east-1"
environment           = "production"
project_name          = "secdo"
jenkins_instance_type = "t3.medium"
app_instance_type     = "t3.small"
ecr_repo_name         = "secdo-app-repo"
ssh_key_name          = "SecDO" # Configured to use SecDO.pem keypair
