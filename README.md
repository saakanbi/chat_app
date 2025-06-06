# Real-time Chat Application

A Node.js and Socket.IO real-time chat application deployed on AWS EC2 with CI/CD pipeline.

## Architecture

- **Application**: Node.js with Socket.IO
- **Server**: AWS EC2 instance
- **Web Server**: Nginx (reverse proxy)
- **Process Manager**: PM2
- **Monitoring**: Prometheus and Grafana
- **CI/CD**: Jenkins pipeline

## Infrastructure

- **Chat App Server**: 3.16.220.117 (Port 80)
- **Jenkins Server**: 3.148.26.127 (Port 8080)
- **Prometheus Server**: 3.137.216.22 (Port 9090)
- **Grafana Server**: 18.226.222.40 (Port 3000)

## Security

- Security groups configured for ports 80 (HTTP) and 443 (HTTPS)
- Firewalld configured on application server

## Deployment Process

The application is deployed using a Jenkins CI/CD pipeline that:

1. Packages the application code
2. Deploys the application to EC2
3. Configures Nginx as a reverse proxy
4. Sets up PM2 for process management
5. Deploys Prometheus and Grafana for monitoring

## Monitoring

- Prometheus collects metrics from all servers
- Grafana provides visualization dashboards
- Node Exporter installed on all servers for system metrics

## Access URLs

- Chat Application: http://3.16.220.117/
- Jenkins: http://3.148.26.127:8080/
- Prometheus: http://3.137.216.22:9090/
- Grafana: http://18.226.222.40:3000/ (admin/admin)

## Project Requirements Fulfilled

- ✅ Deployed on AWS EC2
- ✅ Nginx configured as reverse proxy
- ✅ Public IP assigned
- ✅ Security groups configured for ports 80 and 443
- ✅ Ansible used for configuration
- ✅ Jenkins CI/CD pipeline implemented
- ✅ Monitoring with Prometheus and Grafana