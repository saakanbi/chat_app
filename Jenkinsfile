pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Test') {
            steps {
                sh 'echo "Tests would run here"'
            }
        }
        
        stage('Package') {
            steps {
                sh '''
                    tar -czf chat-app.tar.gz app.js index.html public package.json
                '''
                archiveArtifacts artifacts: 'chat-app.tar.gz', fingerprint: true
            }
        }
        
        stage('Deploy Chat App') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Copy app package to chat server
                        scp -o StrictHostKeyChecking=no chat-app.tar.gz ec2-user@3.16.220.117:/home/ec2-user/
                        
                        # Extract and run app
                        ssh -o StrictHostKeyChecking=no ec2-user@3.16.220.117 "
                            mkdir -p ~/chat-app
                            tar -xzf ~/chat-app.tar.gz -C ~/chat-app
                            cd ~/chat-app
                            npm install
                            sudo npm install -g pm2
                            
                            # Configure Nginx as reverse proxy
                            sudo yum install -y nginx
                            sudo tee /etc/nginx/conf.d/chat-app.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
                            sudo rm -f /etc/nginx/conf.d/default.conf
                            sudo systemctl enable nginx
                            sudo systemctl restart nginx
                            
                            # Configure security for ports 80, 443, and 3000
                            sudo yum install -y firewalld
                            sudo systemctl enable firewalld
                            sudo systemctl start firewalld
                            sudo firewall-cmd --permanent --add-service=http
                            sudo firewall-cmd --permanent --add-service=https
                            sudo firewall-cmd --permanent --add-port=3000/tcp
                            sudo firewall-cmd --reload
                            
                            # Install required dependencies
                            npm install express socket.io uuid
                            
                            # Start the application with PM2
                            pm2 restart app.js || pm2 start app.js --name "chat-app" -- --port 3000
                            pm2 save
                            sudo env PATH=\$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user
                            
                            # Check if app is running and verify network connectivity
                            echo "Checking if app is running..."
                            sleep 5
                            curl -s http://localhost:3000 || echo "App not responding on port 3000"
                            
                            # Verify network connectivity and port status
                            sudo netstat -tulpn | grep 3000
                            sudo ss -tulpn | grep 3000
                            
                            # Ensure SELinux is not blocking connections (if enabled)
                            sudo semanage port -l | grep http_port_t || echo "SELinux management tools not available"
                            
                            # Temporarily disable SELinux for testing if needed
                            sudo setenforce 0 || echo "SELinux not installed"
                        "
                    '''
                }
            }
        }
        
        stage('Deploy Prometheus') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Install Prometheus directly
                        ssh -o StrictHostKeyChecking=no ec2-user@3.137.216.22 "
                            # Install required packages
                            sudo yum install -y wget firewalld
                            
                            # Configure firewall
                            sudo systemctl enable firewalld
                            sudo systemctl start firewalld
                            sudo firewall-cmd --permanent --add-port=9090/tcp
                            sudo firewall-cmd --permanent --add-port=9100/tcp
                            sudo firewall-cmd --reload
                            
                            # Disable firewalld temporarily for testing
                            sudo systemctl stop firewalld
                            
                            # Create Prometheus user
                            sudo useradd -M -r -s /bin/false prometheus || true
                            
                            # Create directories
                            sudo mkdir -p /etc/prometheus /var/lib/prometheus
                            
                            # Download and install Prometheus
                            wget -q https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz -O /tmp/prometheus.tar.gz
                            tar -xf /tmp/prometheus.tar.gz -C /tmp
                            
                            # Copy binaries
                            sudo cp /tmp/prometheus-2.45.0.linux-amd64/prometheus /usr/local/bin/
                            sudo cp /tmp/prometheus-2.45.0.linux-amd64/promtool /usr/local/bin/
                            
                            # Copy config files
                            sudo cp -r /tmp/prometheus-2.45.0.linux-amd64/consoles /etc/prometheus
                            sudo cp -r /tmp/prometheus-2.45.0.linux-amd64/console_libraries /etc/prometheus
                            
                            # Create basic config
                            sudo tee /etc/prometheus/prometheus.yml > /dev/null << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['3.137.216.22:9100', '18.226.222.40:9100', '3.16.220.117:9100']
EOF
                            
                            # Create systemd service
                            sudo tee /etc/systemd/system/prometheus.service > /dev/null << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus/ \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF
                            
                            # Set permissions
                            sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
                            
                            # Start service
                            sudo systemctl daemon-reload
                            sudo systemctl enable prometheus
                            sudo systemctl restart prometheus
                            
                            # Install Node Exporter
                            wget -q https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz -O /tmp/node_exporter.tar.gz
                            tar -xf /tmp/node_exporter.tar.gz -C /tmp
                            sudo cp /tmp/node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/
                            sudo useradd -rs /bin/false node_exporter || true
                            
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
                            
                            sudo systemctl daemon-reload
                            sudo systemctl enable node_exporter
                            sudo systemctl restart node_exporter
                        "
                    '''
                }
            }
        }
        
        stage('Deploy Grafana') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Install Grafana directly
                        ssh -o StrictHostKeyChecking=no ec2-user@18.226.222.40 "
                            # Install required packages
                            sudo yum install -y wget firewalld
                            
                            # Configure firewall
                            sudo systemctl enable firewalld
                            sudo systemctl start firewalld
                            sudo firewall-cmd --permanent --add-port=3000/tcp
                            sudo firewall-cmd --permanent --add-port=9100/tcp
                            sudo firewall-cmd --reload
                            
                            # Disable firewalld temporarily for testing
                            sudo systemctl stop firewalld
                            
                            # Add Grafana repo
                            sudo tee /etc/yum.repos.d/grafana.repo > /dev/null << 'EOF'
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
                            
                            # Install Grafana
                            sudo yum install -y grafana
                            
                            # Configure Grafana
                            sudo tee -a /etc/grafana/grafana.ini > /dev/null << 'EOF'
[auth.anonymous]
enabled = true
org_name = Main Org.
org_role = Viewer
EOF
                            
                            # Start Grafana
                            sudo systemctl daemon-reload
                            sudo systemctl enable grafana-server
                            sudo systemctl restart grafana-server
                            
                            # Install Node Exporter
                            wget -q https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz -O /tmp/node_exporter.tar.gz
                            tar -xf /tmp/node_exporter.tar.gz -C /tmp
                            sudo cp /tmp/node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/
                            sudo useradd -rs /bin/false node_exporter || true
                            
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
                            
                            sudo systemctl daemon-reload
                            sudo systemctl enable node_exporter
                            sudo systemctl restart node_exporter
                            
                            # Wait for Grafana to start
                            sleep 10
                            
                            # Add Prometheus data source
                            curl -s -X POST -H 'Content-Type: application/json' -d '{
                                \"name\":\"Prometheus\",
                                \"type\":\"prometheus\",
                                \"url\":\"http://3.137.216.22:9090\",
                                \"access\":\"proxy\",
                                \"basicAuth\":false
                            }' http://admin:admin@localhost:3000/api/datasources || true
                        "
                    '''
                }
            }
        }
        
        stage('Configure Chat App Monitoring') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Install Node Exporter on Chat App server
                        ssh -o StrictHostKeyChecking=no ec2-user@3.16.220.117 "
                            # Install Node Exporter
                            wget -q https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz -O /tmp/node_exporter.tar.gz
                            tar -xf /tmp/node_exporter.tar.gz -C /tmp
                            sudo cp /tmp/node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/
                            sudo useradd -rs /bin/false node_exporter || true
                            
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
                            
                            # Open firewall for Node Exporter
                            sudo firewall-cmd --permanent --add-port=9100/tcp
                            sudo firewall-cmd --reload
                            
                            sudo systemctl daemon-reload
                            sudo systemctl enable node_exporter
                            sudo systemctl restart node_exporter
                        "
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                def duration = currentBuild.durationString.replace(' and counting', '')
                echo "Build duration: ${duration}"
            }
        }
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}