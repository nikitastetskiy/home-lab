#!/bin/bash

# Colors
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m' # No color

echo "Updating and upgrading system..."
if ! sudo apt-get update -y && sudo apt-get upgrade -y --disable-phased-updates; then
    echo -e "${RED}System update failed! Exiting...${NC}"
    exit 1
fi

echo "Installing OpenSSH Client and Server..."
if ! sudo apt install -y openssh-client openssh-server; then
    echo -e "${RED}OpenSSH installation failed! Exiting...${NC}"
    exit 1
fi

# Final check: Ensure SSH service is running
if systemctl is-active --quiet ssh; then
    echo -e "${GREEN}OpenSSH installation successful and service is running.${NC}"
else
    echo -e "${RED}OpenSSH is installed but the SSH service is not running. Starting service...${NC}"
    sudo systemctl start ssh
    sudo systemctl enable ssh
    if systemctl is-active --quiet ssh; then
        echo -e "${GREEN}OpenSSH service started successfully.${NC}"
    else
        echo -e "${RED}Failed to start OpenSSH service. Exiting...${NC}"
        exit 1
    fi
fi
