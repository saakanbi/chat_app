output "monitoring_public_ip" {
  value       = aws_instance.monitoring_server.public_ip
  description = "Public IP address of the monitoring server (Grafana and Prometheus)"
}

output "monitoring_vpc_id" {
  value       = aws_vpc.monitoring_vpc.id
  description = "ID of the monitoring VPC"
}

output "monitoring_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "ID of the monitoring subnet"
}