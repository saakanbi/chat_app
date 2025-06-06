#!/bin/bash

# This script updates AWS security groups to allow Prometheus to scrape Node Exporter metrics

# Update Prometheus server security group to allow outbound traffic to port 9100
aws ec2 authorize-security-group-egress \
  --group-id sg-prometheus \
  --protocol tcp \
  --port 9100 \
  --cidr 0.0.0.0/0

# Update Grafana server security group to allow inbound traffic from Prometheus on port 9100
aws ec2 authorize-security-group-ingress \
  --group-id sg-grafana \
  --protocol tcp \
  --port 9100 \
  --source-group sg-prometheus

# Update Prometheus server security group to allow inbound traffic from Prometheus on port 9100
aws ec2 authorize-security-group-ingress \
  --group-id sg-prometheus \
  --protocol tcp \
  --port 9100 \
  --source-group sg-prometheus

# Note: Replace sg-prometheus and sg-grafana with your actual security group IDs
# You can find these IDs in the AWS Console under EC2 > Security Groups