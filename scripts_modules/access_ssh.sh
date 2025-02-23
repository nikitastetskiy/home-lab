#!/bin/bash

# Colors for output
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m' # No color

# Ask for backup paths with default values
read -p "Enter the backup path for authorized_keys [Default: /disks/backup/.ssh/authorized_keys]: " AUTHORIZED_KEYS_BACKUP
AUTHORIZED_KEYS_BACKUP=${AUTHORIZED_KEYS_BACKUP:-/disks/backup/.ssh/authorized_keys}

read -p "Enter the backup path for sshd_config [Default: /disks/backup/config_files_backup/sshd_config]: " SSHD_CONFIG_BACKUP
SSHD_CONFIG_BACKUP=${SSHD_CONFIG_BACKUP:-/disks/backup/config_files_backup/sshd_config}

# Define restore paths
AUTHORIZED_KEYS_DEST="$HOME/.ssh/authorized_keys"
SSHD_CONFIG_DEST="/etc/ssh/sshd_config"

# Verify if the backup files exist
if [[ ! -f "$AUTHORIZED_KEYS_BACKUP" ]]; then
    echo -e "${RED}Error: Backup file $AUTHORIZED_KEYS_BACKUP not found.${NC}"
    exit 1
fi

if [[ ! -f "$SSHD_CONFIG_BACKUP" ]]; then
    echo -e "${RED}Error: Backup file $SSHD_CONFIG_BACKUP not found.${NC}"
    exit 1
fi

# Restore authorized_keys
echo -e "${GREEN}Restoring authorized_keys...${NC}"
mkdir -p "$HOME/.ssh"
cp "$AUTHORIZED_KEYS_BACKUP" "$AUTHORIZED_KEYS_DEST"
chmod 600 "$AUTHORIZED_KEYS_DEST"
chown "$USER:$USER" "$AUTHORIZED_KEYS_DEST"

# Restore sshd_config
echo -e "${GREEN}Restoring sshd_config...${NC}"
sudo cp "$SSHD_CONFIG_BACKUP" "$SSHD_CONFIG_DEST"
sudo chmod 644 "$SSHD_CONFIG_DEST"
sudo chown root:root "$SSHD_CONFIG_DEST"

# Restart SSH service
echo -e "${GREEN}Restarting SSH service...${NC}"
sudo systemctl restart ssh

# Verify if SSH restarted successfully
if systemctl is-active --quiet ssh; then
    echo -e "${GREEN}SSH service restarted successfully!${NC}"
else
    echo -e "${RED}Error: SSH service failed to restart.${NC}"
    exit 1
fi

echo -e "${GREEN}Backup restored successfully.${NC}"
exit 0
