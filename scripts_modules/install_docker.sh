#!/bin/bash

# Colors
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m' # No color

echo "Updating and upgrading system..."
sudo apt-get update -y && sudo apt-get upgrade -y

echo "Removing old Docker installations..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg 
done

# Add Docker's official GPG key
echo "Adding Docker's GPG key..."
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources
echo "Adding Docker repository..."
source /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package lists and install Docker
echo "Installing Docker..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify Docker installation
if command -v docker &> /dev/null; then
    echo -e "${GREEN}Installation of Docker: SUCCESS${NC}"
    docker --version
else
    echo -e "${RED}Installation of Docker: FAILED${NC}"
    exit 1
fi
