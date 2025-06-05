output "grafana_public_ip" {
  value       = aws_instance.grafana_server.public_ip
  description = "Public IP address of the Grafana server"
}

output "prometheus_public_ip" {
  value       = aws_instance.prometheus_server.public_ip
  description = "Public IP address of the Prometheus server"
}

output "monitoring_vpc_id" {
  value       = aws_vpc.monitoring_vpc.id
  description = "ID of the monitoring VPC"
}

output "monitoring_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "ID of the monitoring subnet"
}