# Ubuntu Development Environment Setup Script

This script automates the installation and configuration of a complete development environment on Ubuntu-based systems. It's designed to be modular, allowing you to install specific components as needed.

## Features

- Passwordless sudo configuration (with security warnings)
- Nala package manager installation (faster APT alternative)
- Core development tools (curl, git, terminator, etc.)
- Git configuration and SSH key generation
- Google Chrome installation
- Visual Studio Code installation
- Node Version Manager (NVM) setup
- Spotify installation via Snap
- Cascadia Code font installation and configuration
- Docker installation and configuration (run without sudo)
- Tailscale VPN client installation and setup
- JetBrains IDEs installation (DataGrip, WebStorm)
- Postman API client installation
- Timezone fix for dual-boot systems

## Usage

First, make the script executable:

```bash
chmod +x main.sh
chmod +x scripts/*.sh
```

### Install Everything (Default)

To install and configure all components:

```bash
bash main.sh
```

### Install Specific Components

You can choose to install only specific components by providing them as arguments:

```bash
bash main.sh [options]
```

### Available Options:

- `all` - Install and configure everything (default)
- `sudo` - Configure passwordless sudo
- `nala` - Install Nala package manager
- `core` - Install core packages (curl, git, terminator, etc.)
- `git` - Configure Git and generate SSH key
- `chrome` - Install Google Chrome
- `vscode` - Install Visual Studio Code
- `nvm` - Install NVM (Node Version Manager)
- `spotify` - Install Spotify
- `font` - Install Cascadia Code Font
- `docker` - Install Docker and configure to run without sudo
- `tailscale` - Install Tailscale VPN client
- `datagrip` - Install JetBrains DataGrip IDE for databases
- `webstorm` - Install JetBrains WebStorm IDE for web development
- `postman` - Install Postman API client
- `timezone` - Fix timezone for dual boot systems
- `help` - Show this help message

### Examples:

```bash
# Configure Git and generate SSH key only
bash main.sh git

# Install Chrome and VSCode only
bash main.sh chrome vscode

# Show help
bash main.sh help
```

## Project Structure

The project is structured in a modular way:

- `main.sh` - Main entry point of the script
- `scripts/common.sh` - Common functions and variables
- `scripts/system_config.sh` - System configuration functions
- `scripts/dev_tools.sh` - Development tools installation functions
- `scripts/install_apps.sh` - Application installation functions
- `scripts/docker.sh` - Docker installation and configuration functions
- `scripts/tailscale.sh` - Tailscale installation and setup functions
- `scripts/jetbrains.sh` - JetBrains tools (DataGrip, WebStorm) installation functions
- `scripts/postman.sh` - Postman API client installation functions

## Requirements

- Ubuntu-based Linux distribution (tested on Ubuntu 20.04+)
- Internet connection
- Bash shell

## Security Note

The passwordless sudo option is convenient but reduces system security. Only use it in appropriate environments (e.g., development VMs, personal workstations with additional security measures).
