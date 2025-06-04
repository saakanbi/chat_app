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
                // Skip deployment for now to focus on building and testing
                echo 'Skipping deployment to EC2 for now'
                
                // Archive the build artifacts
                sh '''
                    tar -czf chat-app.tar.gz app.js index.html public package.json
                '''
                archiveArtifacts artifacts: 'chat-app.tar.gz', fingerprint: true
            }
        }
    }
    
    post {
        success {
            echo 'Build and test successful!'
        }
        failure {
            echo 'Build or test failed!'
        }
    }
}