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
                    tar -czf ansible.tar.gz ansible-playbook.yml node-exporter-playbook.yml monitoring-playbook.yml unified-inventory.ini ansible.cfg templates/
                '''
                archiveArtifacts artifacts: 'chat-app.tar.gz,ansible.tar.gz', fingerprint: true
            }
        }
        
        stage('Deploy') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Copy packages and SSH key to control node
                        scp -o StrictHostKeyChecking=no chat-app.tar.gz ansible.tar.gz ec2-user@3.16.220.117:/home/ec2-user/
                        
                        # Setup directories and SSH key forwarding
                        ssh -o StrictHostKeyChecking=no ec2-user@3.16.220.117 "
                            mkdir -p ~/chat-app ~/ansible ~/.ssh
                            tar -xzf ~/chat-app.tar.gz -C ~/chat-app
                            tar -xzf ~/ansible.tar.gz -C ~/ansible
                            
                            # Install Ansible if needed
                            if ! command -v ansible &> /dev/null; then
                                sudo amazon-linux-extras install ansible2 -y
                            fi
                            
                            # Deploy chat app
                            cd ~/ansible
                            ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i unified-inventory.ini ansible-playbook.yml
                        "
                    '''
                }
            }
        }
        
        stage('Deploy Monitoring') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Forward SSH agent to control node for monitoring deployment
                        ssh -o StrictHostKeyChecking=no -A ec2-user@3.16.220.117 "
                            cd ~/ansible
                            
                            # Deploy monitoring stack with SSH agent forwarding
                            ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i unified-inventory.ini node-exporter-playbook.yml
                            ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i unified-inventory.ini monitoring-playbook.yml
                        "
                    '''
                }
            }
        }
        
        stage('Setup Jenkins Monitoring') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Configure Prometheus to scrape Jenkins
                        ssh -o StrictHostKeyChecking=no -A ec2-user@3.16.220.117 "
                            ssh -o StrictHostKeyChecking=no ec2-user@3.137.216.22 '
                                sudo tee -a /etc/prometheus/prometheus.yml > /dev/null << EOF
  - job_name: \"jenkins\"
    metrics_path: /prometheus/
    static_configs:
      - targets: [\"3.148.26.127:8080\"]
EOF
                                sudo systemctl restart prometheus
                            '
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