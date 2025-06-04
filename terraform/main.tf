provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "chat_app_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "chat-app-vpc"
  }
}

# Create public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.chat_app_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "chat-app-public-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.chat_app_vpc.id
  tags = {
    Name = "chat-app-igw"
  }
}

# Create Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.chat_app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "chat-app-public-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create Security Group for Chat App
resource "aws_security_group" "chat_app_sg" {
  name        = "chat-app-sg"
  description = "Security group for chat application"
  vpc_id      = aws_vpc.chat_app_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "chat-app-sg"
  }
}

# Create Security Group for Ansible Controller
resource "aws_security_group" "ansible_controller_sg" {
  name        = "ansible-controller-sg"
  description = "Security group for Ansible controller"
  vpc_id      = aws_vpc.chat_app_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "ansible-controller-sg"
  }
}

# Create Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.chat_app_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins web interface
  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "jenkins-sg"
  }
}

# Create Chat App EC2 instance
resource "aws_instance" "chat_app_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.chat_app_sg.id]

  tags = {
    Name = "chat-app-server"
  }
}

# Create Ansible Controller EC2 instance
resource "aws_instance" "ansible_controller" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ansible_controller_sg.id]

  tags = {
    Name = "ansible-controller"
  }

  # Install Ansible and required packages
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install ansible2 -y
    yum install -y git python3-pip
    pip3 install boto3
  EOF
}

# Create Jenkins EC2 instance
resource "aws_instance" "jenkins_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  tags = {
    Name = "jenkins-server"
  }
}

# Allocate Elastic IP for Chat App
resource "aws_eip" "chat_app_eip" {
  instance = aws_instance.chat_app_server.id
  domain   = "vpc"
  tags = {
    Name = "chat-app-eip"
  }
}

# Allocate Elastic IP for Ansible Controller
resource "aws_eip" "ansible_controller_eip" {
  instance = aws_instance.ansible_controller.id
  domain   = "vpc"
  tags = {
    Name = "ansible-controller-eip"
  }
}

# Allocate Elastic IP for Jenkins
resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins_server.id
  domain   = "vpc"
  tags = {
    Name = "jenkins-eip"
  }
}

