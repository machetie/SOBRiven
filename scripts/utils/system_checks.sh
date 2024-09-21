#!/bin/bash

# Function to check if the script is run with root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script with sudo or as root."
        exit 1
    fi
}

# Function to check if user with UID 1000 exists
check_user_1000() {
    if id -u 1000 >/dev/null 2>&1; then
        echo "User with UID 1000 exists."
    else
        echo "Warning: User with UID 1000 does not exist. This may cause permission issues with some containers."
        echo "Consider creating a user with UID 1000 before running this script."
        read -p "Do you want to continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check if group with GID 1000 exists
check_group_1000() {
    if getent group 1000 >/dev/null 2>&1; then
        echo "Group with GID 1000 exists."
    else
        echo "Warning: Group with GID 1000 does not exist. This may cause permission issues with some containers."
        echo "Consider creating a group with GID 1000 before running this script."
        read -p "Do you want to continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check system settings and permissions
check_system() {
    echo "Checking system settings and permissions..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Please install Docker and try again."
        echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
        exit 1
    fi
    
    # Check if Docker is running, if not, try to start it
    if ! docker info &> /dev/null; then
        echo "Docker is not running. Attempting to start Docker..."
        start_docker
    fi
    
    # Check if user has necessary permissions to run Docker
    if ! groups | grep -q docker; then
        echo "Current user is not in the docker group. Adding user to docker group..."
        sudo usermod -aG docker $USER
        echo "Please log out and log back in for the changes to take effect, then run this script again."
        exit 1
    fi
    
    # Check disk space
    available_space=$(df -h / | awk 'NR==2 {print $4}')
    echo "Available disk space: $available_space"
    
    # Check network connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        echo "No internet connection. Please check your network settings."
        exit 1
    fi
    
    echo "System check completed successfully."
}

# Function to start Docker
start_docker() {
    echo "Attempting to start Docker..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open -a Docker
    elif [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        sudo service docker start
    else
        sudo systemctl start docker
    fi
    
    # Wait for Docker to start
    local max_attempts=30
    local attempt=0
    while ! docker info &>/dev/null && [ $attempt -lt $max_attempts ]; do
        echo "Waiting for Docker to start... (attempt $((attempt+1))/$max_attempts)"
        sleep 2
        ((attempt++))
    done

    if ! docker info &>/dev/null; then
        echo "Failed to start Docker automatically. Please try starting Docker manually and run the script again."
        echo "If you're on Linux, you can try: sudo systemctl start docker"
        echo "If you're on macOS, please open the Docker Desktop application."
        echo "If you're on Windows using WSL, try: sudo service docker start"
        exit 1
    fi

    echo "Docker started successfully."
}