#!/bin/bash

install_jellyfin() {
    local mount_point="$1"
    local timezone="$2"

    echo "Installing Jellyfin..."
    docker run -d \
        --name jellyfin \
        --restart unless-stopped \
        -p 8096:8096 \
        -v "$mount_point:/media" \
        -v "./config/jellyfin:/config" \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ="$timezone" \
        jellyfin/jellyfin:latest || { echo "Failed to install Jellyfin"; return 1; }
    
    echo "Jellyfin installed successfully."
}