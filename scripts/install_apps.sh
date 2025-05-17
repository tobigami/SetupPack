#!/bin/bash

# Source common functions and variables
source "$(dirname "$0")/common.sh"

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
