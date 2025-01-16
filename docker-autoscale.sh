#!/bin/bash

# Load configuration from env file
CONFIG_FILE="${1:-docker-autoscale.env}"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found"
    echo "Usage: $0 [config-file-path]"
    echo "Default config file path: docker-autoscale.env"
    exit 1
fi

# Source the configuration file
source "$CONFIG_FILE"

# Validate configuration
validate_config() {
    local required_vars=(
        "SERVICE_NAME"
        "CONTAINER_PREFIX"
        "MIN_INSTANCES"
        "MAX_INSTANCES"
        "CHECK_INTERVAL"
        "CPU_HIGH_THRESHOLD"
        "MEM_HIGH_THRESHOLD"
        "CPU_LOW_THRESHOLD"
        "MEM_LOW_THRESHOLD"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "Error: Required configuration variable $var is not set in $CONFIG_FILE"
            exit 1
        fi
    done

    # Validate numeric values
    if [ "$MIN_INSTANCES" -gt "$MAX_INSTANCES" ]; then
        echo "Error: MIN_INSTANCES cannot be greater than MAX_INSTANCES"
        exit 1
    fi
}

# Function to get container name pattern
get_container_pattern() {
    echo "($CONTAINER_PREFIX|$CONTAINER_PREFIX-[0-9]+)$"
}

# Function to get next available container number
get_next_container_number() {
    local max_num=1
    local pattern=$(get_container_pattern)
    
    docker ps -a --format '{{.Names}}' | grep -E "$pattern" | while read name; do
        if [[ $name == *-* ]]; then
            num=${name##*-}
            if [[ $num =~ ^[0-9]+$ ]] && [ $num -gt $max_num ]; then
                max_num=$num
            fi
        fi
    done
    echo $((max_num + 1))
}

# Function to get running containers
get_running_containers() {
    local pattern=$(get_container_pattern)
    docker ps --format '{{.Names}}' | grep -E "$pattern" | wc -l
}

# Function to get all containers (running and stopped)
get_all_containers() {
    local pattern=$(get_container_pattern)
    docker ps -a --format '{{.Names}}' | grep -E "$pattern" | wc -l
}

# Function to get average CPU usage of running containers
get_avg_cpu() {
    local pattern=$(get_container_pattern)
    docker stats --no-stream --format "{{.CPUPerc}}" $(docker ps --format '{{.Names}}' | grep -E "$pattern") | \
    sed 's/%//g' | \
    awk '{sum+=$1} END {if(NR>0) print int(sum/NR); else print 0}'
}

# Function to get average memory usage of running containers
get_avg_memory() {
    local pattern=$(get_container_pattern)
    docker stats --no-stream --format "{{.MemPerc}}" $(docker ps --format '{{.Names}}' | grep -E "$pattern") | \
    sed 's/%//g' | \
    awk '{sum+=$1} END {if(NR>0) print int(sum/NR); else print 0}'
}

# Function to start the next stopped container
start_next_container() {
    local pattern=$(get_container_pattern)
    STOPPED_CONTAINER=$(docker ps -a --format '{{.Names}}' --filter=status=exited | grep -E "$pattern" | sort |  head -1)
   echo "$STOPPED_CONTAINER"
   if [ ! -z "$STOPPED_CONTAINER" ]; then
        echo "Starting container: $STOPPED_CONTAINER"
        docker start "$STOPPED_CONTAINER"
        return 0
    fi
    return 1
}

# Function to stop the last running container
stop_last_container() {
    if [ "$(get_running_containers)" -gt "$MIN_INSTANCES" ]; then
        local pattern=$(get_container_pattern)
        LAST_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E "$pattern" | sort -V | tail -1)
        echo "Stopping container: $LAST_CONTAINER"
        docker stop "$LAST_CONTAINER"
        return 0
    fi
    return 1
}

# Validate configuration
validate_config

# Validate if service exists
if ! docker ps -a --format '{{.Names}}' | grep -E "$(get_container_pattern)" > /dev/null; then
    echo "Error: No containers found matching service name pattern '$(get_container_pattern)'"
    exit 1
fi

echo "Starting auto-scaling for service: $SERVICE_NAME"
echo "Container name pattern: $(get_container_pattern)"
echo "Using configuration from: $CONFIG_FILE"
echo "Press Ctrl+C to stop"

# Main loop
while true; do
    RUNNING_COUNT=$(get_running_containers)
    TOTAL_COUNT=$(get_all_containers)
    CPU_AVG="0"
    MEM_AVG="0"

    if [ "$RUNNING_COUNT" -gt 0 ]; then
    	CPU_AVG=$(get_avg_cpu)
    	MEM_AVG=$(get_avg_memory)
    fi

    echo "Current status:"
    echo "Running containers: $RUNNING_COUNT/$TOTAL_COUNT"
    echo "Average CPU usage: $CPU_AVG%"
    echo "Average memory usage: $MEM_AVG%"

    # check if al required instance are running and if not start the missing one
    if [ "$RUNNING_COUNT" -lt "$MIN_INSTANCES" ]; then
            echo "There is some required instances that are not running. Starting the missing one ..."
            start_next_container
    fi


    # Scale up condition
    if [ "$CPU_AVG" -gt "$CPU_HIGH_THRESHOLD" ] || \
       [ "$MEM_AVG" -gt "$MEM_HIGH_THRESHOLD" ]; then
        if [ "$RUNNING_COUNT" -lt "$MAX_INSTANCES" ] && [ "$RUNNING_COUNT" -lt "$TOTAL_COUNT" ]; then
            echo "High resource usage detected. Scaling up..."
            start_next_container
        fi
    # Scale down condition
    elif [ "$CPU_AVG" -lt "$CPU_LOW_THRESHOLD" ] && \
         [ "$MEM_AVG" -lt "$MEM_LOW_THRESHOLD" ]; then
        if [ "$RUNNING_COUNT" -gt "$MIN_INSTANCES" ]; then
            echo "Low resource usage detected. Scaling down..."
            stop_last_container
        fi
    fi

    sleep "$CHECK_INTERVAL"
done

