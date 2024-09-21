#!/bin/bash

install_plex() {
    local mount_point="$1"
    local timezone="$2"

    echo "Installing Plex..."

    docker run -d \
        --name plex \
        --restart unless-stopped \
        -p 32400:32400 \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ="$timezone" \
        -e VERSION=docker \
        -v "./config:/config" \
        -v "$mount_point:/mnt" \
        --device /dev/dri:/dev/dri \
        plexinc/pms-docker:latest || { echo "Failed to install Plex"; return 1; }
    
    echo "Plex installed successfully."
}