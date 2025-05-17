#!/bin/bash

# Source common functions and variables
source "$(dirname "$0")/common.sh"

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

# Function to fix timezone for dual boot
fix_timezone() {
    show_section "Timezone Fix for Dual Boot"
    echo "Applying timezone fix for dual boot systems (setting local RTC)..."
    sudo timedatectl set-local-rtc 1 --adjust-system-clock
    echo "${Green}Local RTC set. Current time settings:${Color_Off}"
    timedatectl
    show_separator
}
