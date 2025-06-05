pipeline {
    agent any
    
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
        
        stage('Deploy to EC2') {
            steps {
                // Create deployment package
                sh 'tar -czf chat-app.tar.gz app.js index.html public package.json ansible-playbook.yml inventory.ini ansible.cfg'
                archiveArtifacts artifacts: 'chat-app.tar.gz', fingerprint: true
                
                // Deploy using sshagent for key handling
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Copy files to EC2
                        scp -o StrictHostKeyChecking=no chat-app.tar.gz ec2-user@3.16.220.117:/home/ec2-user/
                        
                        # Extract files on EC2
                        ssh -o StrictHostKeyChecking=no ec2-user@3.16.220.117 "
                            mkdir -p ~/chat-app
                            tar -xzf ~/chat-app.tar.gz -C ~/chat-app
                        "
                        
                        # Install Ansible if not already installed
                        ssh -o StrictHostKeyChecking=no ec2-user@3.16.220.117 "
                            if ! command -v ansible &> /dev/null; then
                                sudo amazon-linux-extras install ansible2 -y
                            fi
                        "
                        
                        # Run Ansible playbook with local connection
                        ssh -o StrictHostKeyChecking=no ec2-user@3.16.220.117 "
                            cd ~/chat-app
                            ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini ansible-playbook.yml --connection=local
                            
                            # Install Node Exporter if not already installed
                            if [ ! -f /usr/local/bin/node_exporter ]; then
                                wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
                                tar xvfz node_exporter-1.5.0.linux-amd64.tar.gz
                                sudo mv node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/
                                sudo useradd -rs /bin/false node_exporter || true
                                
                                # Create systemd service
                                sudo tee /etc/systemd/system/node_exporter.service > /dev/null << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=0.0.0.0:9100

[Install]
WantedBy=multi-user.target
EOF
                                
                                # Start and enable the service
                                sudo systemctl daemon-reload
                                sudo systemctl start node_exporter
                                sudo systemctl enable node_exporter
                            fi
                        "
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
// This Jenkinsfile defines a pipeline for deploying a chat application to an EC2 instance.
// It includes steps for packaging the application, deploying it using Ansible,
// and setting up Node Exporter for monitoring with Prometheus and Grafana.