#!/bin/bash

install_postgres() {
    local postgres_password="$1"

    echo "Installing PostgreSQL for Riven..."
    docker run -d \
        --name riven-db \
        --restart unless-stopped \
        -p 5432:5432 \
        -e PGDATA=/var/lib/postgresql/data/pgdata \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD="$postgres_password" \
        -e POSTGRES_DB=riven \
        -v riven-db:/var/lib/postgresql/data/pgdata \
        --health-cmd "pg_isready -U postgres" \
        --health-interval 10s \
        --health-timeout 5s \
        --health-retries 5 \
        postgres:16.3-alpine3.20 || { echo "Failed to install PostgreSQL for Riven"; return 1; }
    
    echo "PostgreSQL for Riven installed successfully."
}