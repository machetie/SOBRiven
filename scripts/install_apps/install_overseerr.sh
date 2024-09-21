#!/bin/bash

install_overseerr() {
    local timezone="$1"

    echo "Installing Overseerr..."
    docker run -d \
        --name overseerr \
        --restart unless-stopped \
        -p 5055:5055 \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ="$timezone" \
        -v "./config/overseerr:/config" \
        lscr.io/linuxserver/overseerr:latest || { echo "Failed to install Overseerr"; return 1; }
    
    echo "Overseerr installed successfully."
}