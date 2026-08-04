# AWS VPC Infrastructure Module - Public & Private Subnets Architecture

# 1. Custom VPC Definition
resource "aws_vpc" "secdo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 2. Internet Gateway (IGW) for Public Subnets
resource "aws_internet_gateway" "secdo_igw" {
  vpc_id = aws_vpc.secdo_vpc.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# 3. Public Subnets (AZ-a & AZ-b)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.secdo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-1a"
    Type        = "Public"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.secdo_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-1b"
    Type        = "Public"
    Environment = var.environment
  }
}

# 4. Private Subnets (AZ-a & AZ-b) - App & DB Tier
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.secdo_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-private-subnet-1a"
    Type        = "Private"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.secdo_vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-private-subnet-1b"
    Type        = "Private"
    Environment = var.environment
  }
}

# 5. Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.secdo_igw]

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
  }
}

# 6. NAT Gateway in Public Subnet (Provides Secure Outbound Internet for Private Subnets)
resource "aws_nat_gateway" "secdo_nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name        = "${var.project_name}-nat-gateway"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.secdo_igw]
}

# 7. Public Route Table & Associations
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.secdo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secdo_igw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# 8. Private Route Table (Routes Outbound Traffic via NAT Gateway) & Associations
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.secdo_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.secdo_nat_gw.id
  }

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}
