# Output variables for SecDO Infrastructure (Bastion Host + Private Subnets Architecture)

output "vpc_id" {
  description = "Created Custom AWS VPC ID"
  value       = aws_vpc.secdo_vpc.id
}

output "bastion_public_ip" {
  description = "Public IP address of Bastion Host (ONLY public EC2 instance)"
  value       = aws_eip.bastion_eip.public_ip
}

output "alb_dns_name" {
  description = "Public Application Load Balancer DNS Name"
  value       = aws_lb.secdo_alb.dns_name
}

# Web Service URLs accessible in browser via ALB
output "app_url" {
  description = "Production Application Web Access URL"
  value       = "http://${aws_lb.secdo_alb.dns_name}"
}

output "jenkins_url" {
  description = "Jenkins Web Console Access URL"
  value       = "http://${aws_lb.secdo_alb.dns_name}:8080"
}

output "sonarqube_url" {
  description = "SonarQube Web Interface URL"
  value       = "http://${aws_lb.secdo_alb.dns_name}:9000"
}

output "grafana_url" {
  description = "Grafana Observability Dashboard URL"
  value       = "http://${aws_lb.secdo_alb.dns_name}:3000"
}

output "prometheus_url" {
  description = "Prometheus Metrics Explorer URL"
  value       = "http://${aws_lb.secdo_alb.dns_name}:9090"
}

# Internal Private IP Addresses (Accessible strictly via Bastion Host)
output "jenkins_private_ip" {
  description = "Private IP of Jenkins & SonarQube Server"
  value       = aws_instance.jenkins_server.private_ip
}

output "app_private_ip" {
  description = "Private IP of Application & Monitoring Host"
  value       = aws_instance.app_server.private_ip
}

output "ecr_repository_url" {
  description = "AWS ECR Docker Repository URI"
  value       = aws_ecr_repository.secdo_ecr.repository_url
}
