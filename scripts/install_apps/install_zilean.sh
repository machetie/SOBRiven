#!/bin/bash

install_zilean() {
    local postgres_password="$1"
    local timezone="$2"

    echo "Installing Zilean..."
    docker run -d \
        --name zilean \
        --restart unless-stopped \
        -p 8181:8181 \
        -v zilean_data:/app/data \
        -e Zilean__Database__ConnectionString="Host=riven-db;Port=5432;Database=zilean;Username=postgres;Password=$postgres_password" \
        -e Zilean__Dmm__MinimumScoreMatch=0.85 \
        -e Zilean__Imdb__MinimumScoreMatch=0.85 \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ="$timezone" \
        ipromknight/zilean:latest || { echo "Failed to install Zilean"; return 1; }
    
    echo "Zilean installed successfully."
}