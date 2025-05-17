#!/bin/bash

# Text Color Variables
Color_Off=$(tput sgr0) # Text Reset
Red=$(tput setaf 1)    # Red
Green=$(tput setaf 2)  # Green
Yellow=$(tput setaf 3) # Yellow
Purple=$(tput setaf 5) # Purple
Cyan=$(tput setaf 6)   # Cyan

# Get current user from whoami command instead of hardcoding
CURRENT_USER=$(whoami)
HOSTNAME=$(hostname)

echo "${Cyan}===============================================================${Color_Off}"
echo "${Cyan} AUTOMATED TOOL INSTALLATION SCRIPT FOR: ${Purple}$CURRENT_USER@$HOSTNAME${Color_Off}"
echo "${Cyan} Current Date and Time (UTC): ${Purple}2025-05-17 17:01:50${Color_Off}" # Updated timestamp
echo "${Cyan}===============================================================${Color_Off}"
echo ""

# Collect Git configuration information
echo "${Cyan}--- Git Configuration Information ---${Color_Off}"
echo "${Purple}Please enter your Git username (full name):${Color_Off}"
read -r GIT_USERNAME
echo "${Purple}Please enter your Git email:${Color_Off}"
read -r GIT_EMAIL

echo ""
echo "${Red}!!! CRITICAL SECURITY WARNING !!!${Color_Off}"
echo "${Red}This script will attempt to automatically configure PASSWORDLESS SUDO for the user '$CURRENT_USER'.${Color_Off}"
echo "${Red}This significantly reduces system security. Only proceed if you fully understand the risks.${Color_Off}"
echo "${Red}You may be prompted for your password ONCE to enable this setting.${Color_Off}"
echo ""
echo "${Cyan}Press ${Green}Enter${Cyan} to continue, or ${Red}Ctrl+C${Cyan} to cancel.${Color_Off}"
read -r

# --- Tự động cấu hình Sudo không cần mật khẩu ---
echo ""
echo "${Cyan}--- Configuring Passwordless Sudo for $CURRENT_USER ---${Color_Off}"
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
echo "-----------------------------------------------------"
echo ""

# --- Nala Package Manager ---
echo "${Cyan}--- Nala Package Manager ---${Color_Off}"
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

# --- Update package lists (with Nala if available) ---
echo "${Cyan}Updating package lists...${Color_Off}"
if command -v nala &>/dev/null; then
  # Fixed: Remove -y flag for nala update as it doesn't accept it
  sudo nala update
else
  sudo apt update
fi
echo "-----------------------------------------------------"
echo ""

# Function to install packages (uses nala if available, otherwise apt)
install_package() {
  local package_name="$1"
  local display_name="${2:-$1}" # Use a more friendly name for display if provided
  echo "${Cyan}Checking for $display_name...${Color_Off}"
  
  # Check if command exists OR if package is installed (for non-command packages)
  if ! command -v "$package_name" &>/dev/null && ! dpkg -s "$package_name" &>/dev/null 2>&1; then
    echo "Installing $display_name..."
    if command -v nala &>/dev/null; then
      sudo nala install "$package_name" -y  # Fixed: Moved -y flag after package name for nala
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

# --- Install Core Packages ---
echo "${Cyan}--- Installing Core Packages ---${Color_Off}"
install_package "curl" "Curl"
install_package "git" "Git"
install_package "terminator" "Terminator"
install_package "gnome-shell-extension-manager" "GNOME Shell Extension Manager"
echo "-----------------------------------------------------"
echo ""

# --- Git Configuration & SSH Key Generation ---
echo "${Cyan}--- Git Configuration ---${Color_Off}"
if command -v git &>/dev/null; then
  echo "${Green}Configuring Git with provided information...${Color_Off}"
  git config --global user.name "$GIT_USERNAME"
  git config --global user.email "$GIT_EMAIL"
  
  echo "${Green}Git configuration completed:${Color_Off}"
  echo "Name: $(git config --global user.name)"
  echo "Email: $(git config --global user.email)"
  
  # Generate SSH key for Git
  echo "${Cyan}--- Generating SSH Key for Git ---${Color_Off}"
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
echo "-----------------------------------------------------"
echo ""

# --- Google Chrome ---
echo "${Cyan}--- Google Chrome ---${Color_Off}"
if ! command -v google-chrome-stable &> /dev/null; then # More specific command for chrome
    echo "Installing Google Chrome..."
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O google-chrome-stable_current_amd64.deb
    if [ -f google-chrome-stable_current_amd64.deb ]; then
        if command -v nala &>/dev/null; then
            sudo nala install ./google-chrome-stable_current_amd64.deb -y  # Fixed: Moved -y flag
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
echo "-----------------------------------------------------"
echo ""

# --- Visual Studio Code ---
echo "${Cyan}--- Visual Studio Code ---${Color_Off}"
if ! command -v code &> /dev/null; then
    echo "Installing Visual Studio Code..."
    echo "Installing dependencies for VSCode (gpg)..."
    if command -v nala &>/dev/null; then
        # Fixed: Moved -y flag after package names for nala
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
      # Fixed: Removed -y flag from nala update
      sudo nala update
    else
      sudo apt update
    fi
    
    # Fixed: Install VSCode specifically for nala
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
echo "-----------------------------------------------------"
echo ""

# --- NVM (Node Version Manager) ---
echo "${Cyan}--- NVM (Node Version Manager) ---${Color_Off}"
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
echo "-----------------------------------------------------"
echo ""

# --- Spotify ---
echo "${Cyan}--- Spotify ---${Color_Off}"
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
echo "-----------------------------------------------------"
echo ""

# --- Fix Timezone for Dual Boot ---
echo "${Cyan}--- Timezone Fix for Dual Boot ---${Color_Off}"
echo "Applying timezone fix for dual boot systems (setting local RTC)..."
sudo timedatectl set-local-rtc 1 --adjust-system-clock
echo "${Green}Local RTC set. Current time settings:${Color_Off}"
timedatectl
echo "-----------------------------------------------------"
echo ""

echo "${Green}===============================================================${Color_Off}"
echo "${Green} SETUP PROCESS COMPLETED! ${Color_Off}"
echo "${Purple}Some changes (like NVM or new software in PATH) may require you to:${Color_Off}"
echo "${Purple}  1. Close and reopen your terminal.${Color_Off}"
echo "${Purple}  2. Or, log out and log back in.${Color_Off}"
echo "${Purple}  3. Or, source your shell configuration file (e.g., 'source ~/.bashrc').${Color_Off}"
echo "${Green}===============================================================${Color_Off}"