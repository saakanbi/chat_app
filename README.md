# Real-Time Chat Application

A Node.js and Socket.IO based real-time chat application deployed on AWS EC2 with Nginx as a reverse proxy.

## Features

- Real-time messaging using Socket.IO
- User join/leave notifications
- Responsive UI design
- Secure deployment on AWS EC2
- Dedicated Ansible controller instance

## Tech Stack

- **Frontend**: HTML, CSS, JavaScript
- **Backend**: Node.js, Express, Socket.IO
- **Infrastructure**: AWS EC2, Nginx, Terraform
- **CI/CD**: Jenkins
- **Configuration Management**: Ansible

## Deployment Architecture

1. **Chat App EC2 Instance**: Hosts the Node.js application
2. **Ansible Controller EC2 Instance**: Manages configuration and deployment
3. **Nginx**: Acts as a reverse proxy to the Node.js application
4. **Elastic IP**: Provides static public IP addresses for both instances
5. **Security Groups**: Configured for ports 80 (HTTP), 443 (HTTPS), and 22 (SSH)

## Deployment Instructions

### Prerequisites

- AWS Account
- Terraform installed
- SSH key pair for EC2 access

### Infrastructure Setup with Terraform

1. Navigate to the terraform directory:
   ```
   cd terraform
   ```

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Apply the Terraform configuration:
   ```
   terraform apply
   ```

4. Note the output IP addresses for both EC2 instances.

### Automated Deployment

Run the deployment script to provision infrastructure and deploy the application:
```
./deploy.sh
```

The script will:
- Provision AWS infrastructure with Terraform
- Update the Ansible inventory with the EC2 IPs
- Copy files to the Ansible controller
- Deploy the application using Ansible from the controller

### CI/CD with Jenkins

1. Set up a Jenkins pipeline using the provided `Jenkinsfile`.
2. Configure Jenkins credentials for SSH access to the EC2 instances.
3. Trigger the pipeline to deploy changes automatically.

## Local Development

1. Install dependencies:
   ```
   npm install
   ```

2. Start the development server:
   ```
   node app.js
   ```

3. Access the application at `http://localhost:3000`