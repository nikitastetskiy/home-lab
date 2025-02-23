#!/bin/bash

# Colors for output
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m' # No color

# Show available disks before asking
echo -e "${GREEN}Available Disks:${NC}"
lsblk -dpno NAME,SIZE,TYPE | grep disk

# Ask user for the disk
read -p "Enter the disk you want to mount [Default: /dev/sda]: " DISK
DISK=${DISK:-/dev/sda}  # Default to /dev/sda

# Validate if the disk exists
if ! lsblk | grep -q "${DISK##*/}"; then
    echo -e "${RED}Error: Disk $DISK not found!${NC}"
    exit 1
fi

# Ask user for the mount point
read -p "Enter the mount point [Default: /disks]: " MOUNT_POINT
MOUNT_POINT=${MOUNT_POINT:-/disks}  # Default to /disks

# Ask if the user wants to format the disk
read -p "Do you want to format $DISK before mounting? (y/n) [Default: n]: " FORMAT_DISK
FORMAT_DISK=${FORMAT_DISK:-n}

if [[ "$FORMAT_DISK" == "y" ]]; then
    echo -e "${RED}Warning: This will erase all data on $DISK.${NC}"
    read -p "Are you sure? (type 'yes' to confirm): " CONFIRM
    if [[ "$CONFIRM" == "yes" ]]; then
        sudo mkfs.ext4 -F "$DISK"
        echo -e "${GREEN}$DISK formatted successfully.${NC}"
    else
        echo "Skipping format..."
    fi
fi

# Get the UUID of the disk
UUID=$(blkid -s UUID -o value "$DISK")
if [[ -z "$UUID" ]]; then
    echo -e "${RED}Error: No UUID found for $DISK. The disk may need formatting.${NC}"
    exit 1
fi

# Create mount point if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
    echo -e "${GREEN}Created mount point at $MOUNT_POINT.${NC}"
fi

# Ask if user wants to use fstab or autofs
read -p "Do you want to configure auto-mount with fstab or autofs? (fstab/autofs) [Default: fstab]: " MOUNT_METHOD
MOUNT_METHOD=${MOUNT_METHOD:-fstab}

if [[ "$MOUNT_METHOD" == "fstab" ]]; then
    # Check if already in fstab (exact match)
    if grep -qw "UUID=$UUID" /etc/fstab; then
        echo -e "${GREEN}Disk is already configured in /etc/fstab.${NC}"
    else
        echo -e "${GREEN}Adding $DISK to /etc/fstab...${NC}"
        echo "UUID=$UUID $MOUNT_POINT ext4 defaults,noatime,nodiratime,nobarrier,nofail,errors=remount-ro 0 2" | sudo tee -a /etc/fstab > /dev/null
    fi

    # Mount the disk
    sudo mount -a
    echo -e "${GREEN}$DISK successfully mounted at $MOUNT_POINT.${NC}"

elif [[ "$MOUNT_METHOD" == "autofs" ]]; then
    echo "Installing autofs..."
    sudo apt update && sudo apt install -y autofs

    # Configure autofs with the correct mount point
    echo "$MOUNT_POINT /etc/auto.storage --timeout=300" | sudo tee -a /etc/auto.master > /dev/null
    echo "$MOUNT_POINT -fstype=ext4 UUID=$UUID" | sudo tee /etc/auto.storage > /dev/null

    # Restart autofs
    sudo systemctl restart autofs
    echo -e "${GREEN}Auto-mount configured with autofs at $MOUNT_POINT.${NC}"
fi

# Verify if the disk is mounted
if mount | grep -q "$MOUNT_POINT"; then
    echo -e "${GREEN}Disk successfully mounted and ready to use!${NC}"
else
    echo -e "${RED}Error: The disk was not mounted.${NC}"
    exit 1
fi
