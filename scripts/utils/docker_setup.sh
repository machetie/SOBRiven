#!/bin/bash

# Function to create Docker network
create_docker_network() {
    if ! docker network inspect rivenmedia &> /dev/null; then
        echo "Creating Docker network 'rivenmedia'..."
        docker network create rivenmedia || {
            echo "Failed to create Docker network 'rivenmedia'. Please check your Docker installation and permissions."
            exit 1
        }
    else
        echo "Docker network 'rivenmedia' already exists."
    fi
}

# Function to create Docker volumes
create_docker_volumes() {
    local volumes=("zilean_data" "pg-data" "pgadmin-data")
    for volume in "${volumes[@]}"; do
        if ! docker volume inspect "$volume" &> /dev/null; then
            echo "Creating Docker volume '$volume'..."
            docker volume create "$volume" || {
                echo "Failed to create Docker volume '$volume'. Please check your Docker installation and permissions."
                exit 1
            }
        else
            echo "Docker volume '$volume' already exists."
        fi
    done
}