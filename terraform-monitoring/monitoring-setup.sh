#!/bin/bash
# Script to configure Prometheus and Grafana on startup

# Create directories for persistent storage
sudo mkdir -p /var/lib/prometheus_data
sudo mkdir -p /var/lib/grafana_data

# Set permissions
sudo chown -R 65534:65534 /var/lib/prometheus_data
sudo chown -R 472:472 /var/lib/grafana_data

# Create Prometheus config
sudo mkdir -p /etc/prometheus
sudo tee /etc/prometheus/prometheus.yml > /dev/null << 'EOF'
global:
  scrape_interval: 15s
  scrape_timeout: 10s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  
  - job_name: "chat-app"
    static_configs:
      - targets: ["3.16.220.117:9100"]
EOF

# Stop existing containers if running
sudo docker stop prometheus grafana || true
sudo docker rm prometheus grafana || true

# Start Prometheus with persistent storage
sudo docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v /etc/prometheus:/etc/prometheus \
  -v /var/lib/prometheus_data:/prometheus \
  prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus

# Start Grafana with persistent storage
sudo docker run -d \
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