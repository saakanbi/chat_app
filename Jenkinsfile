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
                    // Use Docker to run Ansible with SSH support
                    sh '''
                        docker run --rm \
                        -v "$PWD":/ansible \
                        -v "$SSH_KEY":/ssh-key \
                        -w /ansible \
                        --entrypoint ansible-playbook \
                        willhallonline/ansible:latest \
                        -i ansible-inventory.ini ansible-playbook.yml \
                        --private-key="/ssh-key" -e "ansible_ssh_private_key_file=/ssh-key" \
                        -e "ansible_ssh_common_args='-o StrictHostKeyChecking=no'"
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