#!/bin/bash

# Colors for output
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m' # No color

# Default values
DEFAULT_IP="192.168.1.100"
DEFAULT_GATEWAY="192.168.1.1"
DEFAULT_DNS="8.8.8.8"
DEFAULT_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)

# Show existing Netplan files in red
EXISTING_NETPLANS=$(find /etc/netplan/ -maxdepth 1 -type f -name "*.yaml")
if [ -n "$EXISTING_NETPLANS" ]; then
    echo -e "${RED}Do you want to back up and remove these Netplan configurations before proceeding?${NC}"
    echo -e "${RED}$EXISTING_NETPLANS${NC}"
    
    read -p "(y/n) [Default: n]: " REMOVE_NETPLAN
    REMOVE_NETPLAN=${REMOVE_NETPLAN:-n}
    
    if [[ "$REMOVE_NETPLAN" == "y" ]]; then
        echo "Converting to backup and removing the original Netplan configurations..."
        
        BACKUP_DIR="/etc/netplan/backups"
        mkdir -p "$BACKUP_DIR"

        for file in /etc/netplan/*.yaml; do
            BASENAME=$(basename "$file")  # Extract filename
            cp "$file" "$BACKUP_DIR/${BASENAME%.yaml}_backup.yaml"
            rm -f "$file"  # Remove original file after backup
        done
    fi
fi

#Prompt user for IP (or use default)
read -p "Enter static IP address [Default: $DEFAULT_IP]: " IP_ADDRESS
IP_ADDRESS=${IP_ADDRESS:-$DEFAULT_IP}  # Use default if input is empty

# Prompt for Gateway (or use default)
read -p "Enter Gateway address [Default: $DEFAULT_GATEWAY]: " GATEWAY
GATEWAY=${GATEWAY:-$DEFAULT_GATEWAY}

# Prompt for DNS (or use default)
read -p "Enter DNS server [Default: $DEFAULT_DNS]: " DNS
DNS=${DNS:-$DEFAULT_DNS}

# Confirm interface
read -p "Enter the Interface [Default: $DEFAULT_INTERFACE]: " INTERFACE
INTERFACE=${INTERFACE:-$DEFAULT_INTERFACE}

#Write new Netplan configuration
NETPLAN_FILE="/etc/netplan/01-network-manager-all.yaml"

echo "Applying new static IP configuration..."
tee $NETPLAN_FILE > /dev/null <<EOL
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $IP_ADDRESS/24
      nameservers:
        addresses:
          - $DNS
      routes:
        - to: default
          via: $GATEWAY
EOL

# Fix: Restrict permissions to prevent warnings
sudo chmod 600 $NETPLAN_FILE

# Apply changes
echo "Applying Netplan changes..."
sudo netplan apply

# Final verification
if ip addr show "$INTERFACE" | grep -q "$IP_ADDRESS"; then
    echo -e "${GREEN}Static IP configuration successful!${NC}"
    echo "IP Address: $IP_ADDRESS"
    echo "Gateway: $GATEWAY"
    echo "DNS: $DNS"
    echo "Interface: $INTERFACE"
else
    echo -e "${RED}Failed to apply static IP configuration.${NC}"
    exit 1
fi
