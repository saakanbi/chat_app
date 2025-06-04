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
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                    // Use scp to directly copy files to EC2
                    sh '''
                        # Create a temporary SSH config
                        mkdir -p ~/.ssh
                        cat > ~/.ssh/config << EOF
Host ec2-server
    HostName 3.16.220.117
    User ec2-user
    IdentityFile $SSH_KEY
    StrictHostKeyChecking no
EOF
                        chmod 600 ~/.ssh/config
                        
                        # Create deployment package
                        tar -czf chat-app.tar.gz app.js index.html public package.json
                        
                        # Copy files to EC2
                        scp -F ~/.ssh/config chat-app.tar.gz ec2-server:/home/ec2-user/
                        
                        # Extract and restart service
                        ssh -F ~/.ssh/config ec2-server "mkdir -p /home/ec2-user/chat-app && \
                        tar -xzf /home/ec2-user/chat-app.tar.gz -C /home/ec2-user/chat-app && \
                        cd /home/ec2-user/chat-app && \
                        npm install && \
                        sudo systemctl restart chat-app || echo 'Service not found, may need manual start'"
                        
                        # Archive locally
                        archiveArtifacts artifacts: 'chat-app.tar.gz', fingerprint: true
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