#!/bin/bash

install_riven_frontend() {
    local timezone="$1"
    local postgres_password="$2"

    echo "Installing Riven-Frontend..."

    # Prompt for ORIGIN
    local origin=$(dialog --stdout --inputbox "Enter the ORIGIN (e.g., http://localhost:3000 or your server's IP/domain):" 0 0 "http://localhost:3000")

    docker run -d \
        --name riven-frontend \
        --restart unless-stopped \
        -p 3000:3000 \
        -e ORIGIN="$origin" \
        -e BACKEND_URL=http://riven:8080 \
        -e TZ="$timezone" \
        -e DIALECT=postgres \
        -e DATABASE_URL="postgres://postgres:$postgres_password@riven-db/riven" \
        -e PUID=1000 \
        -e PGID=1000 \
        spoked/riven-frontend:latest || { echo "Failed to install Riven-Frontend"; return 1; }
    
    echo "Riven-Frontend installed successfully."
}