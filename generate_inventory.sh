#!/bin/bash

# Grab the public IP from Terraform output
IP=$(terraform output -raw aws_instance_public_ip)

# Check if IP is empty (error handling)
if [ -z "$IP" ]; then
  echo "Error: Terraform output 'aws_instance_public_ip' is empty."
  exit 1
fi

# Create/update Ansible hosts file
cat > hosts.ini <<EOF
[web]
$IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/terraform_generated_key.pem
EOF

echo "Ansible inventory (hosts.ini) created with IP: $IP"

