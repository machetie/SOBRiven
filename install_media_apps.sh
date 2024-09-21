#!/bin/bash

# Media App Installer Script
# This script provides a graphical menu to install various media apps using Docker
# across different Linux distributions and macOS.

set -e

# Source utility scripts
source scripts/utils/os_detection.sh
source scripts/utils/system_checks.sh
source scripts/utils/docker_setup.sh

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

# Function to install selected apps
install_apps() {
    local apps=("$@")
    local settings=$(get_settings)
    IFS='|' read -r mount_point timezone postgres_password pgadmin_email pgadmin_password riven_real_debrid_api_key riven_plex_token riven_overseerr_api_key <<< "$settings"
    
    for app in "${apps[@]}"; do
        echo "Installing $app..."
        case $app in
            "Plex")
                source scripts/install_apps/install_plex.sh
                install_plex "$mount_point" "$timezone"
                ;;
            "Jellyfin")
                source scripts/install_apps/install_jellyfin.sh
                install_jellyfin "$mount_point" "$timezone"
                ;;
            "Riven")
                source scripts/install_apps/install_riven.sh
                install_riven "$mount_point" "$timezone" "$riven_real_debrid_api_key" "$riven_plex_token" "$riven_overseerr_api_key"
                ;;
            "Riven-Frontend")
                source scripts/install_apps/install_riven_frontend.sh
                install_riven_frontend "$timezone" "$postgres_password"
                ;;
            "Annie")
                source scripts/install_apps/install_annie.sh
                install_annie "$timezone"
                ;;
            "Zilean")
                source scripts/install_apps/install_zilean.sh
                install_zilean "$postgres_password" "$timezone"
                ;;
            "Postgres")
                source scripts/install_apps/install_postgres.sh
                install_postgres "$postgres_password"
                ;;
            "PgAdmin")
                source scripts/install_apps/install_pgadmin.sh
                install_pgadmin "$pgadmin_email" "$pgadmin_password" "$postgres_password"
                ;;
            "Overseerr")
                source scripts/install_apps/install_overseerr.sh
                install_overseerr "$timezone"
                ;;
        esac
        echo "$app installed successfully."
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