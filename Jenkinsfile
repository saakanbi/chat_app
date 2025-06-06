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
                            pm2 restart app.js || pm2 start app.js
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
                            sudo yum install -y wget
                            
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
      - targets: ['3.137.216.22:9100', '18.226.222.40:9100']
  
  - job_name: 'jenkins'
    metrics_path: /prometheus/
    static_configs:
      - targets: ['3.148.26.127:8080']
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
                            sudo yum install -y wget
                            
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