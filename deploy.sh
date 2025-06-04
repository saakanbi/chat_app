#!/bin/bash
# Simple deployment script for the chat app

# Run Ansible playbook with SSH key
ansible-playbook -i ansible-inventory.ini ansible-playbook.yml --private-key=~/.ssh/saturday.pem