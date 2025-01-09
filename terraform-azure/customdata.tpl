#!/bin/bash

# Update the apt package index
sudo apt-get update

# Install packages to allow apt to use a repository over HTTPS
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker APT repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update the apt package index again
sudo apt-get update

# Install the latest version of Docker CE
sudo apt-get install -y docker-ce

# Install Docker Compose
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create directory for OpenRemote
sudo mkdir /openremote

# Download OpenRemote docker-compose.yml
sudo wget https://raw.githubusercontent.com/openremote/openremote/master/docker-compose.yml -P /openremote

# Set environment variables
PUBLIC_IPV4=${public_ip_tf}
OR_HOSTNAME=$PUBLIC_IPV4
OR_ADMIN_PASSWORD="secret"
OR_EMAIL_HOST=""
OR_EMAIL_USER=""
OR_EMAIL_PASSWORD=""
OR_EMAIL_PORT=""
OR_EMAIL_TLS=""
OR_EMAIL_FROM=""
OR_EMAIL_PROTOCOL=""

# Create .env file for Docker Compose
cat <<EOF | sudo tee /openremote/.env
OR_HOSTNAME=$OR_HOSTNAME
OR_ADMIN_PASSWORD=$OR_ADMIN_PASSWORD
OR_EMAIL_HOST=$OR_EMAIL_HOST
OR_EMAIL_USER=$OR_EMAIL_USER
OR_EMAIL_PASSWORD=$OR_EMAIL_PASSWORD
OR_EMAIL_PORT=$OR_EMAIL_PORT
OR_EMAIL_TLS=$OR_EMAIL_TLS
OR_EMAIL_FROM=$OR_EMAIL_FROM
OR_EMAIL_PROTOCOL=$OR_EMAIL_PROTOCOL
EOF

# Create and start OpenRemote instance
sudo docker-compose -f /openremote/docker-compose.yml -p openremote up -d --no-start
sudo docker-compose -f /openremote/docker-compose.yml start

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker