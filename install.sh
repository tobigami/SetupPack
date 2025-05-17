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

# Only display the header when running the script (not when sourcing functions)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_header
fi

# Function to collect git configuration information
setup_git_config() {
    show_section "Git Configuration Information"
    echo "${Purple}Please enter your Git username (full name):${Color_Off}"
    read -r GIT_USERNAME
    echo "${Purple}Please enter your Git email:${Color_Off}"
    read -r GIT_EMAIL
    echo ""
}

# Function to setup passwordless sudo
setup_passwordless_sudo() {
    echo "${Red}!!! CRITICAL SECURITY WARNING !!!${Color_Off}"
    echo "${Red}This script will attempt to automatically configure PASSWORDLESS SUDO for the user '$CURRENT_USER'.${Color_Off}"
    echo "${Red}This significantly reduces system security. Only proceed if you fully understand the risks.${Color_Off}"
    echo "${Red}You may be prompted for your password ONCE to enable this setting.${Color_Off}"
    echo ""
    echo "${Cyan}Press ${Green}Enter${Cyan} to continue, or ${Red}Ctrl+C${Cyan} to cancel.${Color_Off}"
    read -r

    echo ""
    show_section "Configuring Passwordless Sudo for $CURRENT_USER"
    SUDOERS_FILE_PATH="/etc/sudoers.d/$CURRENT_USER"
    SUDOERS_LINE="$CURRENT_USER ALL=(ALL) NOPASSWD: ALL"

    if sudo -n true 2>/dev/null; then
        echo "${Green}Passwordless sudo is already active for $CURRENT_USER.${Color_Off}"
    else
        echo "${Yellow}Passwordless sudo is not active. Attempting to configure...${Color_Off}"
        echo "${Purple}You MAY be prompted for your password ONCE for this setup.${Color_Off}"
        
        # Create the sudoers file entry
        echo "$SUDOERS_LINE" | sudo tee "$SUDOERS_FILE_PATH" > /dev/null
        if [ $? -ne 0 ]; then
            echo "${Red}Failed to write to $SUDOERS_FILE_PATH. Please check permissions or run script with sudo privileges initially if needed.${Color_Off}"
            # exit 1 # Optionally exit if this critical step fails
        fi

        # Set correct permissions for the sudoers file
        sudo chmod 0440 "$SUDOERS_FILE_PATH"
        if [ $? -ne 0 ]; then
            echo "${Red}Failed to set permissions on $SUDOERS_FILE_PATH.${Color_Off}"
            # exit 1 # Optionally exit
        fi

        # Verify if passwordless sudo is now active for subsequent commands
        if sudo -n true 2>/dev/null; then
            echo "${Green}Passwordless sudo configured successfully for $CURRENT_USER.${Color_Off}"
            echo "${Green}Subsequent sudo commands in this script and new terminal sessions should not require a password.${Color_Off}"
        else
            echo "${Red}Failed to automatically activate passwordless sudo for this session immediately.${Color_Off}"
            echo "${Yellow}The configuration may have been written, but it might only take effect in a new terminal session or after a relogin.${Color_Off}"
            echo "${Yellow}You might still be prompted for passwords during the rest of this script if the change hasn't taken effect yet.${Color_Off}"
        fi
    fi
    show_separator
}

# Function to install Nala Package Manager
install_nala() {
    show_section "Nala Package Manager"
    if ! command -v nala &>/dev/null; then
      echo "Nala not found. Installing Nala..."
      sudo apt update # Update before installing nala
      sudo apt install -y nala
      if command -v nala &>/dev/null; then
        echo "${Green}Nala installed successfully.${Color_Off}"
      else
        echo "${Red}Failed to install Nala. Please check for errors. Continuing with apt if possible.${Color_Off}"
      fi
    else
      echo "${Yellow}Nala is already installed.${Color_Off}"
    fi

    # Update package lists (with Nala if available)
    echo "${Cyan}Updating package lists...${Color_Off}"
    if command -v nala &>/dev/null; then
      sudo nala update
    else
      sudo apt update
    fi
    show_separator
}

# Function to install core packages
install_core_packages() {
    show_section "Installing Core Packages"
    install_package "curl" "Curl"
    install_package "git" "Git"
    install_package "terminator" "Terminator"
    install_package "gnome-shell-extension-manager" "GNOME Shell Extension Manager"
    show_separator
}

# Function to setup git and generate SSH key
setup_git() {
    show_section "Git Configuration"
    if command -v git &>/dev/null; then
      echo "${Green}Configuring Git with provided information...${Color_Off}"
      git config --global user.name "$GIT_USERNAME"
      git config --global user.email "$GIT_EMAIL"
      
      echo "${Green}Git configuration completed:${Color_Off}"
      echo "Name: $(git config --global user.name)"
      echo "Email: $(git config --global user.email)"
      
      # Generate SSH key for Git
      show_section "Generating SSH Key for Git"
      SSH_KEY_FILENAME="${GIT_USERNAME}_ssh"
      SSH_KEY_PATH="$HOME/.ssh/$SSH_KEY_FILENAME"
      
      # Create .ssh directory if it doesn't exist
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      
      # Generate SSH key
      echo "${Yellow}Generating SSH key with name $SSH_KEY_FILENAME...${Color_Off}"
      echo "${Purple}We'll use an empty passphrase for this key. Press Enter when prompted.${Color_Off}"
      ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH" -N ""
      
      if [ $? -eq 0 ] && [ -f "$SSH_KEY_PATH" ] && [ -f "$SSH_KEY_PATH.pub" ]; then
        echo "${Green}SSH key generated successfully at $SSH_KEY_PATH${Color_Off}"
        echo "${Green}Your public SSH key is:${Color_Off}"
        echo "$(cat "$SSH_KEY_PATH.pub")"
        echo ""
        echo "${Yellow}Add this SSH key to your GitHub/GitLab account in the SSH keys section.${Color_Off}"
        echo "${Yellow}To copy your public key to clipboard, run:${Color_Off}"
        echo "${Purple}cat $SSH_KEY_PATH.pub | xclip -selection clipboard${Color_Off}"
        
        # Optionally add the key to ssh-agent
        echo "${Cyan}Adding SSH key to ssh-agent...${Color_Off}"
        eval "$(ssh-agent -s)"
        ssh-add "$SSH_KEY_PATH"
        if [ $? -eq 0 ]; then
          echo "${Green}SSH key added to ssh-agent successfully.${Color_Off}"
        else
          echo "${Red}Failed to add SSH key to ssh-agent.${Color_Off}"
        fi
      else
        echo "${Red}Failed to generate SSH key.${Color_Off}"
      fi
    else
      echo "${Red}Git could not be found. Unable to configure Git and generate SSH key.${Color_Off}"
    fi
    show_separator
}

# Function to install Google Chrome
install_chrome() {
    show_section "Google Chrome"
    if ! command -v google-chrome-stable &> /dev/null; then # More specific command for chrome
        echo "Installing Google Chrome..."
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O google-chrome-stable_current_amd64.deb
        if [ -f google-chrome-stable_current_amd64.deb ]; then
            if command -v nala &>/dev/null; then
                sudo nala install ./google-chrome-stable_current_amd64.deb -y
            else
                sudo apt install -y ./google-chrome-stable_current_amd64.deb
            fi
            rm google-chrome-stable_current_amd64.deb
            if command -v google-chrome-stable &> /dev/null; then
                echo "${Green}Google Chrome installed successfully.${Color_Off}"
            else
                echo "${Red}Failed to install Google Chrome after attempting .deb installation.${Color_Off}"
            fi
        else
            echo "${Red}Failed to download Google Chrome .deb package.${Color_Off}"
        fi
    else
        echo "${Yellow}Google Chrome is already installed.${Color_Off}"
    fi
    show_separator
}

# Function to install Visual Studio Code
install_vscode() {
    show_section "Visual Studio Code"
    if ! command -v code &> /dev/null; then
        echo "Installing Visual Studio Code..."
        echo "Installing dependencies for VSCode (gpg)..."
        if command -v nala &>/dev/null; then
            sudo nala install gpg apt-transport-https software-properties-common wget -y
        else
            sudo apt install -y gpg apt-transport-https software-properties-common wget
        fi
        
        echo "Adding Microsoft GPG key and repository for VSCode..."
        VSCODE_GPG_KEY_PATH="/etc/apt/trusted.gpg.d/microsoft.gpg"
        VSCODE_SOURCE_LIST_PATH="/etc/apt/sources.list.d/vscode.list"

        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee "$VSCODE_GPG_KEY_PATH" > /dev/null
        sudo sh -c "echo 'deb [arch=amd64 signed-by=$VSCODE_GPG_KEY_PATH] https://packages.microsoft.com/repos/vscode stable main' > '$VSCODE_SOURCE_LIST_PATH'"
        
        echo "Updating package lists after adding VSCode repository..."
        if command -v nala &>/dev/null; then
          sudo nala update
        else
          sudo apt update
        fi
        
        echo "Installing Visual Studio Code..."
        if command -v nala &>/dev/null; then
          sudo nala install code -y
        else
          sudo apt install -y code
        fi
        
        # Verify installation
        if command -v code &>/dev/null; then
          echo "${Green}Visual Studio Code installed successfully.${Color_Off}"
        else
          echo "${Red}Failed to install Visual Studio Code. Trying alternative method...${Color_Off}"
          
          # Alternative installation method using .deb package
          echo "Attempting alternative installation via .deb package..."
          wget -q "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -O code_latest_amd64.deb
          
          if [ -f code_latest_amd64.deb ]; then
            if command -v nala &>/dev/null; then
              sudo nala install ./code_latest_amd64.deb -y
            else
              sudo apt install -y ./code_latest_amd64.deb
            fi
            rm code_latest_amd64.deb
            
            if command -v code &>/dev/null; then
              echo "${Green}Visual Studio Code installed successfully via .deb package.${Color_Off}"
            else
              echo "${Red}All attempts to install Visual Studio Code failed. Please try manual installation.${Color_Off}"
            fi
          else
            echo "${Red}Failed to download VSCode .deb package.${Color_Off}"
          fi
        fi
    else
        echo "${Yellow}Visual Studio Code is already installed.${Color_Off}"
    fi
    show_separator
}

# Function to install NVM (Node Version Manager)
install_nvm() {
    show_section "NVM (Node Version Manager)"
    NVM_DIR="$HOME/.nvm"
    # Check explicitly for nvm.sh to determine if NVM structure is there
    if ! [ -s "$NVM_DIR/nvm.sh" ]; then # -s checks if file exists and is not empty
        echo "NVM not found. Installing NVM..."
        # Using a specific version for reproducibility, consider checking for the latest.
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        echo "${Green}NVM installation script downloaded and executed.${Color_Off}"
        echo "${Purple}NVM requires sourcing its script. Attempting to source for current session...${Color_Off}"
        if [ -s "$NVM_DIR/nvm.sh" ]; then
            # shellcheck source=/dev/null
            \. "$NVM_DIR/nvm.sh" # Source NVM
            if command -v nvm &>/dev/null; then
                 echo "${Green}NVM sourced successfully for the current session.${Color_Off}"
            else
                echo "${Yellow}NVM command not found after sourcing. Manual sourcing or new terminal may be needed.${Color_Off}"
            fi
            echo "${Purple}To use NVM in new terminals, ensure '$NVM_DIR/nvm.sh' is sourced in your shell profile (e.g., ~/.bashrc or ~/.zshrc).${Color_Off}"
            echo "${Purple}The NVM installer usually adds this automatically to .bashrc. You might need to add it to .zshrc if you use Zsh.${Color_Off}"
        else
            echo "${Red}NVM script not found at $NVM_DIR/nvm.sh after installation attempt.${Color_Off}"
            echo "${Yellow}Please check the NVM installation manually. You might need to close and reopen your terminal.${Color_Off}"
        fi
    else
        echo "${Yellow}NVM installation directory found at $NVM_DIR.${Color_Off}"
        # Source NVM if it's installed but not sourced in the current session
        if ! command -v nvm &>/dev/null; then # Check if nvm command is not available
            echo "${Purple}NVM command not available in current session. Attempting to source...${Color_Off}"
            if [ -s "$NVM_DIR/nvm.sh" ]; then
                 # shellcheck source=/dev/null
                 \. "$NVM_DIR/nvm.sh"
                 if command -v nvm &>/dev/null; then
                    echo "${Green}NVM (already installed) sourced successfully for the current session.${Color_Off}"
                 else
                    echo "${Yellow}Failed to source NVM. Manual sourcing or new terminal may be needed.${Color_Off}"
                 fi
            else
                echo "${Red}NVM script $NVM_DIR/nvm.sh not found or empty. Cannot source.${Color_Off}"
            fi
        else
            echo "${Green}NVM command is already available.${Color_Off}"
        fi
    fi
    show_separator
}

# Function to install Spotify
install_spotify() {
    show_section "Spotify"
    if ! snap list | grep -q spotify; then
        echo "Spotify not found via Snap. Installing Spotify..."
        if ! command -v snap &>/dev/null; then
            echo "Snapd not found. Installing Snapd..."
            install_package "snapd" "Snapd"
        fi
        if command -v snap &>/dev/null; then # Check if snapd installed successfully
            sudo snap install spotify
            if snap list | grep -q spotify; then
                echo "${Green}Spotify installed successfully via Snap.${Color_Off}"
            else
                echo "${Red}Failed to install Spotify via Snap after attempting.${Color_Off}"
            fi
        else
            echo "${Red}Snapd is not available. Cannot install Spotify via Snap.${Color_Off}"
        fi
    else
        echo "${Yellow}Spotify is already installed via Snap.${Color_Off}"
    fi
    show_separator
}

# Function to install Cascadia Code Font
install_cascadia_font() {
    show_section "Cascadia Code Font"
    FONT_DIR="/usr/share/fonts/truetype/cascadia-code"
    if [ -d "$FONT_DIR" ] && fc-list | grep -q "Cascadia"; then
        echo "${Yellow}Cascadia Code font appears to be already installed.${Color_Off}"
    else
        echo "Installing Cascadia Code font..."
        # Create temporary directory for download
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR" || exit
        
        # Download the latest release from GitHub
        echo "Downloading Cascadia Code font from Microsoft GitHub..."
        wget -q https://github.com/microsoft/cascadia-code/releases/download/v2111.01/CascadiaCode-2111.01.zip
        
        if [ -f "CascadiaCode-2111.01.zip" ]; then
            echo "Extracting Cascadia Code font files..."
            unzip -q CascadiaCode-2111.01.zip
            
            # Create font directory
            sudo mkdir -p "$FONT_DIR"
            
            # Copy the TTF files to the system fonts directory
            echo "Installing font files to system directory..."
            sudo cp -f ttf/*.ttf "$FONT_DIR/"
            
            # Update font cache
            echo "Updating font cache..."
            sudo fc-cache -f
            
            # Verify installation
            if fc-list | grep -q "Cascadia"; then
                echo "${Green}Cascadia Code font installed successfully.${Color_Off}"
                
                # Configure as default monospace font for the system
                echo "Setting Cascadia Code as default monospace font..."
                
                # Ensure the gsettings command is available
                if command -v gsettings &>/dev/null; then
                    # For GNOME Desktop Environment
                    gsettings set org.gnome.desktop.interface monospace-font-name 'Cascadia Code 11'
                    if [ $? -eq 0 ]; then
                        echo "${Green}Cascadia Code set as default monospace font in GNOME settings.${Color_Off}"
                        echo "${Yellow}Note: This setting applies to the current user only.${Color_Off}"
                    else
                        echo "${Red}Failed to set Cascadia Code as default monospace font via gsettings.${Color_Off}"
                    fi
                else
                    echo "${Yellow}gsettings command not found. Cannot set Cascadia Code as default font automatically.${Color_Off}"
                    echo "${Yellow}To set manually, go to Settings > Appearance > Fonts and select 'Cascadia Code'.${Color_Off}"
                fi
            else
                echo "${Red}Failed to verify Cascadia Code font installation.${Color_Off}"
            fi
        else
            echo "${Red}Failed to download Cascadia Code font.${Color_Off}"
        fi
        
        # Clean up
        cd - > /dev/null || exit
        rm -rf "$TEMP_DIR"
    fi
    show_separator
}

# Function to fix timezone for dual boot
fix_timezone() {
    show_section "Timezone Fix for Dual Boot"
    echo "Applying timezone fix for dual boot systems (setting local RTC)..."
    sudo timedatectl set-local-rtc 1 --adjust-system-clock
    echo "${Green}Local RTC set. Current time settings:${Color_Off}"
    timedatectl
    show_separator
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
    echo "  timezone     Fix timezone for dual boot systems"
    echo "  help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                   # Run the full installation"
    echo "  $0 git               # Configure Git and generate SSH key only"
    echo "  $0 chrome vscode     # Install Chrome and VSCode only"
}

# Main function to run the script with arguments
main() {
    # If no arguments, run everything
    if [ $# -eq 0 ] || [ "$1" = "all" ]; then
        setup_git_config
        setup_passwordless_sudo
        install_nala
        install_core_packages
        setup_git
        install_chrome
        install_vscode
        install_nvm
        install_spotify
        install_cascadia_font
        fix_timezone
        show_completion
        exit 0
    fi

    # Check for help argument
    if [[ "$1" = "help" || "$1" = "--help" || "$1" = "-h" ]]; then
        show_usage
        exit 0
    fi

    # Process specific installation options
    for option in "$@"; do
        case "$option" in
            sudo)
                setup_git_config  # We need the username for sudo
                setup_passwordless_sudo
                ;;
            nala)
                install_nala
                ;;
            core)
                install_core_packages
                ;;
            git)
                setup_git_config
                setup_git
                ;;
            chrome)
                install_chrome
                ;;
            vscode)
                install_vscode
                ;;
            nvm)
                install_nvm
                ;;
            spotify)
                install_spotify
                ;;
            font)
                install_cascadia_font
                ;;
            timezone)
                fix_timezone
                ;;
            *)
                echo "${Red}Unknown option: $option${Color_Off}"
                show_usage
                exit 1
                ;;
        esac
    done

    show_completion
}

# Run the main function with all arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi