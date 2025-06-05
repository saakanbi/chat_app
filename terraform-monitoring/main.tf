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
    
    # Create monitoring setup script
    cat > /home/ec2-user/monitoring-setup.sh << 'SCRIPT'
#!/bin/bash
# Script to configure Prometheus and Grafana on startup

# Create directories for persistent storage
mkdir -p /var/lib/prometheus_data
mkdir -p /var/lib/grafana_data

# Set permissions
chown -R 65534:65534 /var/lib/prometheus_data
chown -R 472:472 /var/lib/grafana_data

# Create Prometheus config
mkdir -p /etc/prometheus
cat > /etc/prometheus/prometheus.yml << 'CONFIG'
global:
  scrape_interval: 15s
  scrape_timeout: 10s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  
  - job_name: "chat-app"
    static_configs:
      - targets: ["${var.chat_app_private_ip}:9100"]
CONFIG

# Stop existing containers if running
docker stop prometheus grafana || true
docker rm prometheus grafana || true

# Start Prometheus with persistent storage
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v /etc/prometheus:/etc/prometheus \
  -v /var/lib/prometheus_data:/prometheus \
  prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus

# Start Grafana with persistent storage
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -v /var/lib/grafana_data:/var/lib/grafana \
  grafana/grafana

# Wait for Grafana to start
echo "Waiting for Grafana to start..."
sleep 10

# Configure Grafana data source
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"Prometheus","type":"prometheus","url":"http://localhost:9090","access":"proxy","isDefault":true}' \
  http://admin:admin@localhost:3000/api/datasources

# Import dashboard
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": {
      "id": null,
      "title": "Chat App Dashboard",
      "tags": ["chat-app"],
      "timezone": "browser",
      "panels": [
        {
          "title": "CPU Usage",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
          "targets": [{"expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"}]
        },
        {
          "title": "Memory Usage",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
          "targets": [
            {"expr": "node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes"},
            {"expr": "node_memory_MemTotal_bytes"}
          ]
        },
        {
          "title": "Network Traffic",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
          "targets": [
            {"expr": "rate(node_network_receive_bytes_total{device!=\"lo\"}[5m])"},
            {"expr": "rate(node_network_transmit_bytes_total{device!=\"lo\"}[5m])"}
          ]
        },
        {
          "title": "Disk Usage",
          "type": "graph",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
          "targets": [
            {"expr": "node_filesystem_avail_bytes{mountpoint=\"/\"}"},
            {"expr": "node_filesystem_size_bytes{mountpoint=\"/\"} - node_filesystem_avail_bytes{mountpoint=\"/\"}"}
          ]
        }
      ]
    },
    "folderId": 0,
    "overwrite": true
  }' \
  http://admin:admin@localhost:3000/api/dashboards/db

echo "Monitoring setup complete!"
SCRIPT

    # Make script executable
    chmod +x /home/ec2-user/monitoring-setup.sh
    
    # Run the setup script
    /home/ec2-user/monitoring-setup.sh
    
    # Add to crontab to run on reboot
    (crontab -l 2>/dev/null; echo "@reboot /home/ec2-user/monitoring-setup.sh") | crontab -
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
    
    # Create monitoring setup script
    cat > /home/ec2-user/monitoring-setup.sh << 'SCRIPT'
#!/bin/bash
# Script to configure Prometheus on startup

# Create directories for persistent storage
mkdir -p /var/lib/prometheus_data

# Set permissions
chown -R 65534:65534 /var/lib/prometheus_data

# Create prometheus config directory
mkdir -p /etc/prometheus

# Create a basic prometheus.yml configuration
cat > /etc/prometheus/prometheus.yml << 'CONFIG'
global:
  scrape_interval: 15s
  scrape_timeout: 10s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'chat-app'
    static_configs:
      - targets: ['${var.chat_app_private_ip}:9100']
CONFIG

# Stop existing container if running
docker stop prometheus || true
docker rm prometheus || true

# Run Prometheus with persistent storage
docker run -d -p 9090:9090 --name prometheus \
  -v /etc/prometheus:/etc/prometheus \
  -v /var/lib/prometheus_data:/prometheus \
  prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus

echo "Prometheus setup complete!"
SCRIPT

    # Make script executable
    chmod +x /home/ec2-user/monitoring-setup.sh
    
    # Run the setup script
    /home/ec2-user/monitoring-setup.sh
    
    # Add to crontab to run on reboot
    (crontab -l 2>/dev/null; echo "@reboot /home/ec2-user/monitoring-setup.sh") | crontab -
  EOF
}