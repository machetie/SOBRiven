#!/bin/bash

install_annie() {
    local timezone="$1"

    echo "Installing Annie..."
    docker run -d \
        --name annie \
        --restart unless-stopped \
        -p 6633:3000 \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ="$timezone" \
        -v "./config/annie:/config" \
        ghcr.io/gaisberg/annie:latest || { echo "Failed to install Annie"; return 1; }
    
    echo "Annie installed successfully."
}