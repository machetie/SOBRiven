# Media App Installer

This script provides a modular and customizable way to install various media applications using Docker across different Linux distributions and macOS.

## Features

- Supports installation of Plex, Jellyfin, Riven, Riven-Frontend, Annie, Zilean, Postgres, PgAdmin, and Overseerr.
- Automatically detects the operating system and installs necessary dependencies.
- Uses Docker for easy deployment and management of applications.
- Provides a user-friendly dialog-based menu for selecting applications to install.
- Allows customization of installation parameters through a configuration file.
- Supports Riven-specific environment variables for advanced configuration.

## Prerequisites

- Bash shell
- Docker
- dialog (will be installed if not present)

## File Structure

```
.
├── install_media_apps.sh
├── config.sh
├── scripts/
│   ├── utils/
│   │   ├── os_detection.sh
│   │   ├── system_checks.sh
│   │   └── docker_setup.sh
│   └── install_apps/
│       ├── install_plex.sh
│       ├── install_jellyfin.sh
│       ├── install_riven.sh
│       ├── install_riven_frontend.sh
│       ├── install_annie.sh
│       ├── install_zilean.sh
│       ├── install_postgres.sh
│       ├── install_pgadmin.sh
│       └── install_overseerr.sh
└── README.md
```

## Usage

1. Clone this repository or download all the files to your local machine.

2. Make the main script executable:
   ```
   chmod +x install_media_apps.sh
   ```

3. (Optional) Edit the `config.sh` file to set your preferred default values.

4. Run the script:
   ```
   sudo ./install_media_apps.sh
   ```

5. Follow the on-screen prompts to select the applications you want to install and provide any necessary information.

## Configuration

You can customize the default values by editing the `config.sh` file. This file contains variables for:

- Mount point for media
- API token (if applicable)
- URL (if applicable)
- Timezone
- PostgreSQL password
- PgAdmin email and password

### Riven-specific Environment Variables

The `config.sh` file includes Riven-specific environment variables that you can customize:

- Real-Debrid downloader settings
- All-Debrid downloader settings
- Torbox downloader settings
- Overseerr integration settings
- Torrentio scraping settings
- Zilean scraping settings
- Plex integration settings

When installing Riven, you will be prompted to configure these variables or use the default values from `config.sh`.

## Logs

The installation process is logged to `installation_log.txt` in the same directory as the script.

## Troubleshooting

If you encounter any issues during the installation:

1. Check the `installation_log.txt` file for error messages.
2. Ensure that Docker is installed and running correctly on your system.
3. Verify that you have sufficient permissions to run Docker commands.
4. Make sure you have a stable internet connection.

### Arch-based Systems

If you encounter dependency conflicts on Arch-based systems (like Garuda Linux), follow these steps:

1. Update your system: `sudo pacman -Syu`
2. If there are conflicts, resolve them manually.
3. Install dialog and docker: `sudo pacman -S dialog docker`
4. If you encounter issues with ffmpeg, try: `sudo pacman -S ffmpeg4.4`
5. Run the installation script again after resolving the issues.

## Contributing

Feel free to submit issues or pull requests if you find any bugs or have suggestions for improvements.

## License

This project is open-source and available under the MIT License.