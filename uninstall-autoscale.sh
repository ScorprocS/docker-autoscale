#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Stop and disable the service
echo "Stopping and disabling service..."
systemctl stop docker-autoscale
systemctl disable docker-autoscale

# Remove PID files
echo "Removing PID files..."
rm -f /var/run/docker-autoscale-*.pid

# Remove scripts
echo "Removing scripts..."
rm -f /usr/local/bin/docker-autoscale.sh
rm -f /usr/local/bin/docker-autoscale-multiple.sh
rm -f /etc/systemd/system/docker-autoscale.service

# Remove configuration and log files
echo "Removing configuration and log files..."
#rm -rf /etc/docker-autoscale
rm -f /var/log/docker-autoscale.log
rm -f /var/log/docker-autoscale.error.log

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Uninstallation complete!"

