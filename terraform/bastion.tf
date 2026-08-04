# Bastion Host (Jump Server) Provisioning in Public Subnet

resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security Group for Public Bastion Host"
  vpc_id      = aws_vpc.secdo_vpc.id

  # Inbound SSH Access from anywhere or admin IP
  ingress {
    description = "SSH Access to Bastion Host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound All Traffic to VPC Private Subnets
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-bastion-sg"
    Environment = var.environment
  }
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion_host" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  key_name                    = var.ssh_key_name
  subnet_id                   = aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = file("${path.module}/../scripts/setup-bastion.sh")

  tags = {
    Name        = "${var.project_name}-bastion-host"
    Role        = "Public Jump Server"
    Subnet      = "Public Subnet 1a"
    Environment = var.environment
  }
}

# Elastic IP for Bastion Host
resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion_host.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-bastion-eip"
    Environment = var.environment
  }
}
