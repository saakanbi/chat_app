# Monitoring Infrastructure

This Terraform configuration creates a separate infrastructure for monitoring tools (Grafana and Prometheus).

## Resources Created

- VPC with public subnet
- Internet Gateway and routing
- Security group for monitoring tools
- Grafana server (EC2 instance with Docker)
- Prometheus server (EC2 instance with Docker)

## Usage

1. Initialize Terraform:
   ```
   terraform init
   ```

2. Apply the configuration with the chat app's private IP:
   ```
   terraform apply -var="chat_app_private_ip=10.0.1.123"
   ```
   Replace `10.0.1.123` with the actual private IP of your chat app server.

3. Access the monitoring tools:
   - Grafana: http://[grafana_public_ip]:3000 (default credentials: admin/admin)
   - Prometheus: http://[prometheus_public_ip]:9090

## Node Exporter

To collect metrics from your chat app server, you need to install Node Exporter on it.
Add the following to your chat app deployment script or Ansible playbook:

```bash
# Install Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.5.0.linux-amd64.tar.gz
sudo mv node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/
sudo useradd -rs /bin/false node_exporter

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
```