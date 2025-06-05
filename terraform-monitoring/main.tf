provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "monitoring_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "monitoring-vpc"
  }
}

# Create public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.monitoring_vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "monitoring-public-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.monitoring_vpc.id
  tags = {
    Name = "monitoring-igw"
  }
}

# Create Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.monitoring_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "monitoring-public-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for Monitoring Tools
resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-sg"
  description = "Security group for monitoring tools (Grafana and Prometheus)"
  vpc_id      = aws_vpc.monitoring_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana web interface
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus web interface
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-sg"
  }
}

# Grafana Server EC2 instance
resource "aws_instance" "grafana_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.monitoring_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "grafana-server"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    docker run -d -p 3000:3000 --name grafana grafana/grafana
  EOF
}

# Prometheus Server EC2 instance
resource "aws_instance" "prometheus_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.monitoring_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "prometheus-server"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    
    # Create prometheus config directory
    mkdir -p /etc/prometheus
    
    # Create a basic prometheus.yml configuration
    cat > /etc/prometheus/prometheus.yml << 'PROMCONFIG'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'chat-app'
    static_configs:
      - targets: ['${var.chat_app_private_ip}:9100']
PROMCONFIG

    # Run Prometheus with the configuration
    docker run -d -p 9090:9090 --name prometheus \
      -v /etc/prometheus:/etc/prometheus \
      prom/prometheus --config.file=/etc/prometheus/prometheus.yml
  EOF
}