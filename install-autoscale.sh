#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Create necessary directories and files
echo "Creating directories and files..."
mkdir -p /usr/local/bin
mkdir -p /etc/docker-autoscale
touch /var/log/docker-autoscale.log
touch /var/log/docker-autoscale.error.log
chmod 644 /var/log/docker-autoscale.log
chmod 644 /var/log/docker-autoscale.error.log

# Copy files to their locations
echo "Installing files..."
cp docker-autoscale.sh /usr/local/bin/
cp docker-autoscale.env /etc/docker-autoscale/
cp docker-autoscale.service /etc/systemd/system/
# Copy the multiple service script
cp docker-autoscale-multiple.sh /usr/local/bin/

# Set correct permissions
echo "Setting permissions..."
chmod +x /usr/local/bin/docker-autoscale.sh
chmod 644 /etc/docker-autoscale/docker-autoscale.env
chmod 644 /etc/systemd/system/docker-autoscale.service
chmod +x /usr/local/bin/docker-autoscale-multiple.sh

# Create directory for PID files
mkdir -p /var/run

# Modify script to use the correct config file location
sed -i 's|CONFIG_FILE="${1:-docker-autoscale.env}"|CONFIG_FILE="${1:-/etc/docker-autoscale/docker-autoscale.env}"|' /usr/local/bin/docker-autoscale.sh

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start the service
echo "Enabling and starting service..."
systemctl enable docker-autoscale.service
systemctl start docker-autoscale.service

echo "Installation complete!"
echo "You can check the service status with: systemctl status docker-autoscale"
echo "Logs are available at:"
echo "  - /var/log/docker-autoscale.log"
echo "  - /var/log/docker-autoscale.error.log"
