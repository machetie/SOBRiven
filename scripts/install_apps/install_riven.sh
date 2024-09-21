#!/bin/bash

install_riven() {
    local mount_point="$1"
    local timezone="$2"

    echo "Installing Riven..."

    # Prompt user for Riven-specific environment variables
    local use_riven_env=$(dialog --stdout --yesno "Do you want to configure Riven-specific environment variables?" 0 0)
    local riven_env=""

    if [ $? -eq 0 ]; then
        RIVEN_FORCE_ENV=$(dialog --stdout --inputbox "Force use of environment variables? (true/false)" 0 0 "true")
        RIVEN_SYMLINK_RCLONE_PATH=$(dialog --stdout --inputbox "Rclone mount path:" 0 0 "/mnt/zurg/__all__")
        RIVEN_SYMLINK_LIBRARY_PATH=$(dialog --stdout --inputbox "Symlink library path:" 0 0 "/mnt/library")
        RIVEN_DATABASE_HOST=$(dialog --stdout --inputbox "Database host:" 0 0 "postgresql+psycopg2://postgres:postgres@riven-db/riven")
        RIVEN_DOWNLOADERS_REAL_DEBRID_ENABLED=$(dialog --stdout --inputbox "Enable Real-Debrid downloader? (true/false)" 0 0 "true")
        RIVEN_DOWNLOADERS_REAL_DEBRID_API_KEY=$(dialog --stdout --inputbox "Real-Debrid API Key:" 0 0)
        RIVEN_UPDATERS_PLEX_ENABLED=$(dialog --stdout --inputbox "Enable Plex updater? (true/false)" 0 0 "true")
        RIVEN_UPDATERS_PLEX_URL=$(dialog --stdout --inputbox "Plex URL:" 0 0 "http://plex:32400")
        RIVEN_UPDATERS_PLEX_TOKEN=$(dialog --stdout --inputbox "Plex Token:" 0 0)
        RIVEN_CONTENT_OVERSEERR_ENABLED=$(dialog --stdout --inputbox "Enable Overseerr integration? (true/false)" 0 0 "true")
        RIVEN_CONTENT_OVERSEERR_URL=$(dialog --stdout --inputbox "Overseerr URL:" 0 0 "http://overseerr:5055")
        RIVEN_CONTENT_OVERSEERR_API_KEY=$(dialog --stdout --inputbox "Overseerr API Key:" 0 0)
        RIVEN_SCRAPING_TORRENTIO_ENABLED=$(dialog --stdout --inputbox "Enable Torrentio scraping? (true/false)" 0 0 "true")
        RIVEN_SCRAPING_ZILEAN_ENABLED=$(dialog --stdout --inputbox "Enable Zilean scraping? (true/false)" 0 0 "true")
        RIVEN_SCRAPING_ZILEAN_URL=$(dialog --stdout --inputbox "Zilean URL:" 0 0 "http://zilean:8181")

        riven_env="-e RIVEN_FORCE_ENV=$RIVEN_FORCE_ENV \
                   -e RIVEN_SYMLINK_RCLONE_PATH=$RIVEN_SYMLINK_RCLONE_PATH \
                   -e RIVEN_SYMLINK_LIBRARY_PATH=$RIVEN_SYMLINK_LIBRARY_PATH \
                   -e RIVEN_DATABASE_HOST=$RIVEN_DATABASE_HOST \
                   -e RIVEN_DOWNLOADERS_REAL_DEBRID_ENABLED=$RIVEN_DOWNLOADERS_REAL_DEBRID_ENABLED \
                   -e RIVEN_DOWNLOADERS_REAL_DEBRID_API_KEY=$RIVEN_DOWNLOADERS_REAL_DEBRID_API_KEY \
                   -e RIVEN_UPDATERS_PLEX_ENABLED=$RIVEN_UPDATERS_PLEX_ENABLED \
                   -e RIVEN_UPDATERS_PLEX_URL=$RIVEN_UPDATERS_PLEX_URL \
                   -e RIVEN_UPDATERS_PLEX_TOKEN=$RIVEN_UPDATERS_PLEX_TOKEN \
                   -e RIVEN_CONTENT_OVERSEERR_ENABLED=$RIVEN_CONTENT_OVERSEERR_ENABLED \
                   -e RIVEN_CONTENT_OVERSEERR_URL=$RIVEN_CONTENT_OVERSEERR_URL \
                   -e RIVEN_CONTENT_OVERSEERR_API_KEY=$RIVEN_CONTENT_OVERSEERR_API_KEY \
                   -e RIVEN_SCRAPING_TORRENTIO_ENABLED=$RIVEN_SCRAPING_TORRENTIO_ENABLED \
                   -e RIVEN_SCRAPING_ZILEAN_ENABLED=$RIVEN_SCRAPING_ZILEAN_ENABLED \
                   -e RIVEN_SCRAPING_ZILEAN_URL=$RIVEN_SCRAPING_ZILEAN_URL"
    fi

    docker run -d \
        --name riven \
        --restart unless-stopped \
        -p 8080:8080 \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ="$timezone" \
        $riven_env \
        -v "./data:/riven/data" \
        -v "$mount_point:/mnt" \
        --health-cmd "curl -s http://localhost:8080 >/dev/null || exit 1" \
        --health-interval 30s \
        --health-timeout 10s \
        --health-retries 10 \
        spoked/riven:latest || { echo "Failed to install Riven"; return 1; }
    
    echo "Riven installed successfully."
}