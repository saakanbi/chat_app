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
                
                // Deploy using sshagent for better key handling
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Copy files to EC2
                        scp -o StrictHostKeyChecking=no chat-app.tar.gz ec2-user@3.16.220.117:/home/ec2-user/
                        
                        # Extract and restart service
                        ssh -o StrictHostKeyChecking=no ec2-user@3.16.220.117 "mkdir -p /home/ec2-user/chat-app && \
                        tar -xzf /home/ec2-user/chat-app.tar.gz -C /home/ec2-user/chat-app && \
                        cd /home/ec2-user/chat-app && \
                        npm install && \
                        sudo systemctl restart chat-app || echo 'Service not found, may need manual start'"
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