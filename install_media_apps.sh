#!/bin/bash

# Media App Installer Script
# This script provides a graphical menu to install various media apps using Docker
# across different Linux distributions and macOS.

set -e

# Base URL for raw GitHub content
BASE_URL="https://github.com/machetie/SOBRiven/raw/main/"

# Function to download and source a script from GitHub
source_from_github() {
    local script_path="$1"
    local temp_file=$(mktemp)
    wget -q -O "$temp_file" "${BASE_URL}${script_path}"
    source "$temp_file"
    rm "$temp_file"
}

# Source utility scripts
source_from_github "scripts/utils/os_detection.sh"
source_from_github "scripts/utils/system_checks.sh"
source_from_github "scripts/utils/docker_setup.sh"

# Function to display the menu and get user selection
display_menu() {
    local options=(
        "Plex" "Media server for organizing and streaming your media" off
        "Jellyfin" "Open source media server" off
        "Riven" "Media management and automation tool" off
        "Riven-Frontend" "Web interface for Riven" off
        "Annie" "Video downloader" off
        "Zilean" "Subtitle downloader and manager" off
        "Postgres" "Database for storing media metadata" off
        "PgAdmin" "Web-based PostgreSQL administration tool" off
        "Overseerr" "Request management and media discovery tool" off
    )

    local cmd=(dialog --separate-output --checklist "Select media apps to install:" 22 76 16)
    local choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    
    echo "$choices"
}

# Function to check if a package is installed
is_package_installed() {
    local package=$1
    case $os in
        "macOS")
            brew list $package &>/dev/null
            ;;
        "WSL" | "Debian-based")
            dpkg -s $package &>/dev/null
            ;;
        "RedHat-based")
            rpm -q $package &>/dev/null
            ;;
        "Arch-based")
            pacman -Qi $package &>/dev/null
            ;;
        "SUSE-based")
            rpm -q $package &>/dev/null
            ;;
        "Alpine")
            apk info -e $package &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
    return $?
}

# Function to install dependencies
install_dependencies() {
    local os=$1
    echo "Checking dependencies for $os..."
    local install_dialog=false
    local install_docker=false

    if ! is_package_installed "dialog"; then
        install_dialog=true
    fi

    if ! is_package_installed "docker"; then
        install_docker=true
    fi

    if [ "$install_dialog" = false ] && [ "$install_docker" = false ]; then
        echo "All required dependencies are already installed."
        return
    fi

    echo "Installing missing dependencies..."
    case $os in
        "macOS")
            [ "$install_dialog" = true ] && brew install dialog
            [ "$install_docker" = true ] && brew install docker
            ;;
        "WSL" | "Debian-based")
            check_root
            [ "$install_dialog" = true ] && apt-get install -y dialog
            [ "$install_docker" = true ] && apt-get install -y docker.io
            ;;
        "RedHat-based")
            check_root
            [ "$install_dialog" = true ] && dnf install -y dialog
            [ "$install_docker" = true ] && dnf install -y docker
            ;;
        "Arch-based")
            check_root
            if ! pacman -S --noconfirm $([ "$install_dialog" = true ] && echo "dialog") $([ "$install_docker" = true ] && echo "docker"); then
                echo "Failed to install dependencies. Please try the following steps:"
                echo "1. Update your system: sudo pacman -Syu"
                echo "2. If there are conflicts, resolve them manually"
                echo "3. Install missing dependencies: sudo pacman -S dialog docker"
                echo "4. Run this script again after resolving the issues"
                exit 1
            fi
            ;;
        "SUSE-based")
            check_root
            [ "$install_dialog" = true ] && zypper install -y dialog
            [ "$install_docker" = true ] && zypper install -y docker
            ;;
        "Alpine")
            check_root
            [ "$install_dialog" = true ] && apk add --no-cache dialog
            [ "$install_docker" = true ] && apk add --no-cache docker
            ;;
        "Other-Linux")
            echo "Your Linux distribution is not specifically supported."
            echo "Please ensure 'dialog' and 'docker' are installed manually, then run this script again."
            exit 1
            ;;
        *)
            echo "Unknown operating system. Please install 'dialog' and 'docker' manually, then run this script again."
            exit 1
            ;;
    esac
    echo "Dependencies checked and installed if necessary."
}

# Function to get additional settings
get_settings() {
    local mount_point=$(dialog --stdout --inputbox "Enter mount point for media:" 0 0)
    local timezone=$(dialog --stdout --inputbox "Enter timezone (e.g., America/New_York):" 0 0 "America/New_York")
    local postgres_password=$(dialog --stdout --passwordbox "Enter PostgreSQL password:" 0 0)
    local pgadmin_email=$(dialog --stdout --inputbox "Enter PgAdmin email:" 0 0 "postgres@example.com")
    local pgadmin_password=$(dialog --stdout --passwordbox "Enter PgAdmin password:" 0 0)
    local riven_real_debrid_api_key=$(dialog --stdout --passwordbox "Enter Real-Debrid API Key for Riven:" 0 0)
    local riven_plex_token=$(dialog --stdout --passwordbox "Enter Plex Token for Riven:" 0 0)
    local riven_overseerr_api_key=$(dialog --stdout --passwordbox "Enter Overseerr API Key for Riven:" 0 0)
    
    echo "$mount_point|$timezone|$postgres_password|$pgadmin_email|$pgadmin_password|$riven_real_debrid_api_key|$riven_plex_token|$riven_overseerr_api_key"
}

# Function to check existing containers and their permissions
check_existing_containers() {
    local app=$1
    local container_name

    case $app in
        "Plex")
            container_name="plex"
            ;;
        "Jellyfin")
            container_name="jellyfin"
            ;;
        "Riven")
            container_name="riven"
            ;;
        "Riven-Frontend")
            container_name="riven-frontend"
            ;;
        "Annie")
            container_name="annie"
            ;;
        "Zilean")
            container_name="zilean"
            ;;
        "Postgres")
            container_name="postgres"
            ;;
        "PgAdmin")
            container_name="pgadmin"
            ;;
        "Overseerr")
            container_name="overseerr"
            ;;
        *)
            echo "Unknown app: $app"
            return 1
            ;;
    esac

    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "Container $container_name already exists."
        local permissions=$(docker inspect --format='{{.HostConfig.Privileged}}' $container_name)
        echo "Container permissions: $permissions"
        
        local choice=$(dialog --stdout --menu "Container $container_name already exists. What would you like to do?" 15 60 4 \
            1 "Skip installation" \
            2 "Reinstall (delete existing and create new)" \
            3 "Update permissions")
        
        case $choice in
            1)
                echo "Skipping installation of $app"
                return 1
                ;;
            2)
                echo "Removing existing container $container_name"
                docker rm -f $container_name
                return 0
                ;;
            3)
                local new_permissions=$(dialog --stdout --menu "Select new permissions for $container_name:" 15 60 2 \
                    1 "Normal" \
                    2 "Privileged")
                
                if [ "$new_permissions" = "2" ]; then
                    echo "Updating $container_name to privileged mode"
                    docker update --privileged $container_name
                else
                    echo "Updating $container_name to normal mode"
                    docker update --privileged=false $container_name
                fi
                return 1
                ;;
        esac
    fi
    
    return 0
}

# Function to install selected apps
install_apps() {
    local apps=("$@")
    local settings=$(get_settings)
    IFS='|' read -r mount_point timezone postgres_password pgadmin_email pgadmin_password riven_real_debrid_api_key riven_plex_token riven_overseerr_api_key <<< "$settings"
    
    for app in "${apps[@]}"; do
        echo "Checking $app..."
        if check_existing_containers "$app"; then
            echo "Installing $app..."
            case $app in
                "Plex")
                    source_from_github "scripts/install_apps/install_plex.sh"
                    install_plex "$mount_point" "$timezone"
                    ;;
                "Jellyfin")
                    source_from_github "scripts/install_apps/install_jellyfin.sh"
                    install_jellyfin "$mount_point" "$timezone"
                    ;;
                "Riven")
                    source_from_github "scripts/install_apps/install_riven.sh"
                    install_riven "$mount_point" "$timezone" "$riven_real_debrid_api_key" "$riven_plex_token" "$riven_overseerr_api_key"
                    ;;
                "Riven-Frontend")
                    source_from_github "scripts/install_apps/install_riven_frontend.sh"
                    install_riven_frontend "$timezone" "$postgres_password"
                    ;;
                "Annie")
                    source_from_github "scripts/install_apps/install_annie.sh"
                    install_annie "$timezone"
                    ;;
                "Zilean")
                    source_from_github "scripts/install_apps/install_zilean.sh"
                    install_zilean "$postgres_password" "$timezone"
                    ;;
                "Postgres")
                    source_from_github "scripts/install_apps/install_postgres.sh"
                    install_postgres "$postgres_password"
                    ;;
                "PgAdmin")
                    source_from_github "scripts/install_apps/install_pgadmin.sh"
                    install_pgadmin "$pgadmin_email" "$pgadmin_password" "$postgres_password"
                    ;;
                "Overseerr")
                    source_from_github "scripts/install_apps/install_overseerr.sh"
                    install_overseerr "$timezone"
                    ;;
            esac
            echo "$app installed successfully."
        else
            echo "Skipping $app installation."
        fi
    done
}

# Main script execution
main() {
    local os=$(detect_os)
    echo "Detected OS: $os"
    
    if [ "$os" == "Unknown" ]; then
        echo "Unable to determine your operating system. Please ensure you have 'dialog' and 'docker' installed, then run this script again."
        exit 1
    fi
    
    check_root
    check_user_1000
    check_group_1000
    install_dependencies "$os"
    check_system
    create_docker_volumes
    
    local selected_apps=$(display_menu)
    
    if [ $? -eq 0 ] && [ -n "$selected_apps" ]; then
        install_apps $selected_apps
        echo "Installation completed successfully."
    else
        echo "No apps selected or user cancelled. Exiting."
        exit 0
    fi
}

# Run the main function
main 2>&1 | tee installation_log.txt