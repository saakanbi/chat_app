output "public_ip" {
  value = aws_eip.chat_app_eip.public_ip
  description = "Public IP address of the chat application server"
}

output "ansible_controller_public_ip" {
  value = aws_eip.ansible_controller_eip.public_ip
  description = "Public IP address of the Ansible controller"
}

output "grafana_public_ip" {
  value = aws_eip.grafana_eip.public_ip
  description = "Public IP address of the Grafana server"
}

output "prometheus_public_ip" {
  value = aws_eip.prometheus_eip.public_ip
  description = "Public IP address of the Prometheus server"
}