#!/bin/bash

# Directory containing configuration files
CONFIG_DIR="/etc/docker-autoscale"
AUTOSCALE_SCRIPT="/usr/local/bin/docker-autoscale.sh"

# Check if the config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: Configuration directory $CONFIG_DIR not found"
    exit 1
fi

# Check if the main script exists
if [ ! -f "$AUTOSCALE_SCRIPT" ]; then
    echo "Error: Auto-scale script $AUTOSCALE_SCRIPT not found"
    exit 1
fi

# Function to start auto-scaling for a config file
start_autoscale() {
    local config_file="$1"
    echo "Starting auto-scaling for config: $config_file"
    $AUTOSCALE_SCRIPT "$config_file" &
    echo $! > "/var/run/docker-autoscale-$(basename "$config_file" .env).pid"
}

# Function to stop all auto-scaling processes
stop_autoscales() {
    echo "Stopping all auto-scaling processes..."
    for pid_file in /var/run/docker-autoscale-*.pid; do
        if [ -f "$pid_file" ]; then
            pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                echo "Stopping process $pid"
                kill "$pid"
            fi
            rm "$pid_file"
        fi
    done
}

# Handle SIGTERM gracefully
trap 'stop_autoscales; exit 0' SIGTERM

# Count configuration files
config_files=("$CONFIG_DIR"/*.env)
if [ ${#config_files[@]} -eq 0 ]; then
    echo "Error: No .env configuration files found in $CONFIG_DIR"
    exit 1
fi

# Start auto-scaling for each configuration file
echo "Starting auto-scaling processes..."
for config_file in "${config_files[@]}"; do
    if [ -f "$config_file" ]; then
        start_autoscale "$config_file"
        echo "Started auto-scaling for: $config_file"
    fi
done

# Keep the script running and monitor child processes
while true; do
    # Check if any process died and restart it
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            pid_file="/var/run/docker-autoscale-$(basename "$config_file" .env).pid"
            if [ -f "$pid_file" ]; then
                pid=$(cat "$pid_file")
                if ! kill -0 "$pid" 2>/dev/null; then
                    echo "Process for $config_file died, restarting..."
                    start_autoscale "$config_file"
                fi
            else
                echo "PID file missing for $config_file, restarting..."
                start_autoscale "$config_file"
            fi
        fi
    done
    sleep 300
done
