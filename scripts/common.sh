#!/bin/bash

# Text Color Variables
Color_Off=$(tput sgr0) # Text Reset
Red=$(tput setaf 1)    # Red
Green=$(tput setaf 2)  # Green
Yellow=$(tput setaf 3) # Yellow
Purple=$(tput setaf 5) # Purple
Cyan=$(tput setaf 6)   # Cyan

# Declare global variables
CURRENT_USER=$(whoami)
HOSTNAME=$(hostname)
GIT_USERNAME=""
GIT_EMAIL=""

# Function to display header
show_header() {
    echo "${Cyan}===============================================================${Color_Off}"
    echo "${Cyan} AUTOMATED TOOL INSTALLATION SCRIPT FOR: ${Purple}$CURRENT_USER@$HOSTNAME${Color_Off}"
    echo "${Cyan} Current Date and Time (UTC): ${Purple}$(date -u '+%Y-%m-%d %H:%M:%S')${Color_Off}"
    echo "${Cyan}===============================================================${Color_Off}"
    echo ""
}

# Function to display section header
show_section() {
    local section_name="$1"
    echo "${Cyan}--- $section_name ---${Color_Off}"
}

# Function to display section separator
show_separator() {
    echo "-----------------------------------------------------"
    echo ""
}

# Function to install packages (uses nala if available, otherwise apt)
install_package() {
  local package_name="$1"
  local display_name="${2:-$1}" # Use a more friendly name for display if provided
  echo "${Cyan}Checking for $display_name...${Color_Off}"
  
  # Check if command exists OR if package is installed (for non-command packages)
  if ! command -v "$package_name" &>/dev/null && ! dpkg -s "$package_name" &>/dev/null 2>&1; then
    echo "Installing $display_name..."
    if command -v nala &>/dev/null; then
      sudo nala install "$package_name" -y
    else
      sudo apt install -y "$package_name"
    fi
    
    if command -v "$package_name" &>/dev/null || dpkg -s "$package_name" &>/dev/null 2>&1; then
        echo "${Green}$display_name installed successfully.${Color_Off}"
    else
        echo "${Red}Failed to install or verify $display_name.${Color_Off}"
    fi
  else
    echo "${Yellow}$display_name is already installed.${Color_Off}"
  fi
  echo "---"
}

# Function to show completion message
show_completion() {
    echo "${Green}===============================================================${Color_Off}"
    echo "${Green} SETUP PROCESS COMPLETED! ${Color_Off}"
    echo "${Purple}Some changes (like NVM or new software in PATH) may require you to:${Color_Off}"
    echo "${Purple}  1. Close and reopen your terminal.${Color_Off}"
    echo "${Purple}  2. Or, log out and log back in.${Color_Off}"
    echo "${Purple}  3. Or, source your shell configuration file (e.g., 'source ~/.bashrc').${Color_Off}"
    echo "${Green}===============================================================${Color_Off}"
}

# Function to show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  all          Install and configure everything (default if no option is specified)"
    echo "  sudo         Configure passwordless sudo"
    echo "  nala         Install Nala package manager"
    echo "  core         Install core packages (curl, git, terminator, gnome-shell-extension-manager)"
    echo "  git          Configure Git and generate SSH key"
    echo "  chrome       Install Google Chrome"
    echo "  vscode       Install Visual Studio Code"
    echo "  nvm          Install NVM (Node Version Manager)"
    echo "  spotify      Install Spotify"
    echo "  font         Install Cascadia Code Font"
    echo "  docker       Install Docker and configure to run without sudo"
    echo "  timezone     Fix timezone for dual boot systems"
    echo "  help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                   # Run the full installation"
    echo "  $0 git               # Configure Git and generate SSH key only"
    echo "  $0 chrome vscode     # Install Chrome and VSCode only"
}
