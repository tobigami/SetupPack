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
- Timezone fix for dual-boot systems

## Usage

First, make the script executable:

```bash
chmod +x install.sh
```

### Install Everything (Default)

To install and configure all components:

```bash
./install.sh
```

### Install Specific Components

You can choose to install only specific components by providing them as arguments:

```bash
./install.sh [options]
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
- `timezone` - Fix timezone for dual boot systems
- `help` - Show this help message

### Examples:

```bash
# Configure Git and generate SSH key only
./install.sh git

# Install Chrome and VSCode only
./install.sh chrome vscode

# Show help
./install.sh help
```

## Requirements

- Ubuntu-based Linux distribution (tested on Ubuntu 20.04+)
- Internet connection
- Bash shell

## Security Note

The passwordless sudo option is convenient but reduces system security. Only use it in appropriate environments (e.g., development VMs, personal workstations with additional security measures).
