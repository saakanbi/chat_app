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
                sh 'npm install'
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
                    sh '''
                        # Run Ansible playbook with explicit SSH key
                        ansible-playbook -i ansible-inventory.ini ansible-playbook.yml --private-key="$SSH_KEY" -e "ansible_ssh_private_key_file=$SSH_KEY"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Deployment successful!'
            slackSend(color: 'good', message: "Deployment successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
        failure {
            echo 'Deployment failed!'
            slackSend(color: 'danger', message: "Deployment failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
    }
}