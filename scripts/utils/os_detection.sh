#!/bin/bash

# Function to detect the operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        echo "WSL"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint|elementary|zorin)
                echo "Debian-based"
                ;;
            fedora|centos|rhel|rocky|almalinux)
                echo "RedHat-based"
                ;;
            arch|manjaro|endeavouros|garuda)
                echo "Arch-based"
                ;;
            opensuse*|sles)
                echo "SUSE-based"
                ;;
            alpine)
                echo "Alpine"
                ;;
            *)
                echo "Other-Linux"
                ;;
        esac
    else
        echo "Unknown"
    fi
}