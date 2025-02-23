#!/bin/sh

# Ensure the script runs in Bash
if [ -z "$BASH_VERSION" ]; then
    exec sudo bash "$0" "$@"
fi

# Verify if the script is run under privileged user
if [ "$EUID" -ne 0 ]; then
	echo "This script should be run with a privileged user. Exiting..."
	exit 1
fi

# Menu
echo "Choose an option:"
echo "1 - Initialize Disks"
echo "2 - Docker installation"
echo "3 - SSH installation"
echo "4 - Configure static IP"
echo "5 - Configure SSH access"
echo "6 - Configure containers"

# Input
read -p "Insert your options (1,2,3...): " opt

IFS=',' read -ra SLCT <<< "$opt"

for o in "${SLCT[@]}"; do
    case "$o" in
        1)
            echo "Configuring Disks and fstab..."
            bash scripts_modules/disks.sh
            ;;   
        2)
            echo "Installing Docker..."
            bash scripts_modules/install_docker.sh
            ;;
        3)
            echo "Installing SSH..."
            bash scripts_modules/install_ssh.sh
            ;;
        4)
            echo "Configuring static IP..."
            bash scripts_modules/static_ip.sh
            ;;
        5)
            echo "Configuring SSH access..."
            bash scripts_modules/access_ssh.sh
            ;;
        6)
            echo "Configuring Containers..."
            bash scripts_modules/containers.sh
            ;;
        *)
            echo "Not a valid option: $o"
            ;;
    esac
done

echo "Exiting..."
exit 0
