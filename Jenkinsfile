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
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    // Create a temporary directory for SSH key with proper permissions
                    sh '''
                        # Create temp directory for SSH key
                        SSH_DIR="$(mktemp -d)"
                        echo "$SSH_KEY" > "$SSH_DIR/id_rsa"
                        chmod 600 "$SSH_DIR/id_rsa"
                        
                        # Run Ansible in Docker with the SSH key
                        docker run --rm \
                        -v "$PWD":/ansible \
                        -v "$SSH_DIR":/ssh \
                        -w /ansible \
                        --entrypoint ansible-playbook \
                        willhallonline/ansible:latest \
                        -i ansible-inventory.ini ansible-playbook.yml \
                        --private-key="/ssh/id_rsa" \
                        -e "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
                        -e "ansible_user=ec2-user"
                        
                        # Clean up
                        rm -rf "$SSH_DIR"
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