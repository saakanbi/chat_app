pipeline {
    agent any
    
    tools {
        nodejs 'NodeJS' // Use the NodeJS installation configured in Jenkins
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                // Use Docker to run npm install to avoid GLIBC version issues
                sh '''
                    docker run --rm -v "$PWD":/app -w /app node:16-alpine npm install
                '''
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
                sh 'tar -czf chat-app.tar.gz app.js index.html public package.json'
                archiveArtifacts artifacts: 'chat-app.tar.gz', fingerprint: true
                
                // Deploy using sshagent for key handling
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Copy files to EC2 first
                        scp -o StrictHostKeyChecking=no chat-app.tar.gz ec2-user@3.16.220.117:/home/ec2-user/
                        
                        # Run commands directly on EC2 to set up the application
                        ssh -o StrictHostKeyChecking=no ec2-user@3.16.220.117 "
                            # Install required packages if not already installed
                            sudo yum update -y
                            sudo amazon-linux-extras install epel -y
                            sudo yum install -y nginx git curl lsof
                            
                            # Install Node.js if not already installed
                            if ! command -v node &> /dev/null; then
                                curl -fsSL https://rpm.nodesource.com/setup_16.x | sudo bash -
                                sudo yum install -y nodejs
                            fi
                            
                            # Extract application files
                            mkdir -p ~/chat-app
                            tar -xzf ~/chat-app.tar.gz -C ~/chat-app
                            cd ~/chat-app
                            npm install
                            
                            # Configure Nginx
                            sudo tee /etc/nginx/conf.d/chat-app.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \\$host;
        proxy_cache_bypass \\$http_upgrade;
    }
}
EOF
                            
                            # Create systemd service
                            sudo tee /etc/systemd/system/chat-app.service > /dev/null << 'EOF'
[Unit]
Description=Node.js Chat Application
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user/chat-app
ExecStart=/usr/bin/node app.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=chat-app

[Install]
WantedBy=multi-user.target
EOF
                            
                            # Reload systemd, stop any running instances, and start services
                            sudo systemctl daemon-reload
                            sudo systemctl stop chat-app || true
                            sudo lsof -ti:3000 | sudo xargs -r kill -9
                            sudo systemctl enable chat-app
                            sudo systemctl start chat-app
                            sudo systemctl enable nginx
                            sudo systemctl restart nginx
                            
                            # Check status
                            echo 'Chat App Status:'
                            sudo systemctl status chat-app --no-pager
                            echo 'Nginx Status:'
                            sudo systemctl status nginx --no-pager
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