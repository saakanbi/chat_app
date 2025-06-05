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