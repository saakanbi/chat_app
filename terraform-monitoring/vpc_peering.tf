# VPC Peering Connection
resource "aws_vpc_peering_connection" "monitoring_to_chat_app" {
  peer_vpc_id = "vpc-0a8f602aef101146c"  # Chat App VPC ID
  vpc_id      = aws_vpc.monitoring_vpc.id
  auto_accept = true

  tags = {
    Name = "monitoring-to-chat-app-peering"
  }
}

# Update route table for monitoring VPC to route traffic to chat app VPC
resource "aws_route" "monitoring_to_chat_app" {
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = "10.0.0.0/16"  # Chat App VPC CIDR
  vpc_peering_connection_id = aws_vpc_peering_connection.monitoring_to_chat_app.id
}

# Create a route in the chat app VPC route table to route traffic to monitoring VPC
resource "aws_route" "chat_app_to_monitoring" {
  route_table_id            = "rtb-0a82d7047b6f9ffe9"  # Chat App main route table ID
  destination_cidr_block    = "10.1.0.0/16"  # Monitoring VPC CIDR
  vpc_peering_connection_id = aws_vpc_peering_connection.monitoring_to_chat_app.id
}