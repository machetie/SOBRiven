#!/bin/bash

install_pgadmin() {
    local pgadmin_email="$1"
    local pgadmin_password="$2"
    local postgres_password="$3"

    echo "Installing PgAdmin..."

    # Create pgadmin_servers.json
    echo '{
        "Servers": {
            "1": {
                "Group": "Servers",
                "Name": "Zilean Database",
                "Host": "postgres",
                "Port": 5432,
                "MaintenanceDB": "zilean",
                "Username": "postgres",
                "PassFile": "/pgpass",
                "SSLMode": "prefer"
            }
        }
    }' > pgadmin_servers.json

    # Create pgadmin_pgpass
    echo "postgres:5432:*:postgres:$postgres_password" > pgadmin_pgpass

    docker run -d \
        --name pgadmin \
        -p 6001:80 \
        -e PGADMIN_DEFAULT_EMAIL="$pgadmin_email" \
        -e PGADMIN_DEFAULT_PASSWORD="$pgadmin_password" \
        -e PGADMIN_CONFIG_SERVER_MODE=False \
        -e PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=False \
        -v pgadmin-data:/var/lib/pgadmin \
        -v "$PWD/pgadmin_servers.json:/pgadmin4/servers.json" \
        -v "$PWD/pgadmin_pgpass:/pgpass" \
        --network rivenmedia \
        dpage/pgadmin4 || { echo "Failed to install PgAdmin"; return 1; }

    # Clean up temporary files
    rm pgadmin_servers.json pgadmin_pgpass

    echo "PgAdmin installed successfully."
}