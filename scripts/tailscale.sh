#!/bin/bash

# Source common functions and variables
source "$(dirname "$0")/common.sh"

# Function to install Tailscale
install_tailscale() {
    show_section "Tailscale"
    
    # Check if Tailscale is already installed
    if command -v tailscale &>/dev/null; then
        echo "${Yellow}Tailscale appears to be already installed.${Color_Off}"
        echo "Current version: $(tailscale version 2>/dev/null || echo 'Could not determine version')"
    else
        echo "${Cyan}Tailscale not found. Installing Tailscale...${Color_Off}"
        
        # Add Tailscale's GPG key
        echo "${Cyan}Adding Tailscale's GPG key...${Color_Off}"
        curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
        
        # Add the Tailscale repository
        echo "${Cyan}Adding Tailscale repository...${Color_Off}"
        curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
        
        # Update package index
        echo "${Cyan}Updating package index...${Color_Off}"
        if command -v nala &>/dev/null; then
            sudo nala update
        else
            sudo apt-get update
        fi
        
        # Install Tailscale
        echo "${Cyan}Installing Tailscale...${Color_Off}"
        if command -v nala &>/dev/null; then
            sudo nala install -y tailscale
        else
            sudo apt-get install -y tailscale
        fi
        
        # Verify Tailscale installation
        if command -v tailscale &>/dev/null; then
            echo "${Green}Tailscale installed successfully.${Color_Off}"
            echo "Version: $(tailscale version 2>/dev/null || echo 'Could not determine version')"
        else
            echo "${Red}Failed to install Tailscale. Please check for errors.${Color_Off}"
            return 1
        fi
    fi
    
    # Ask if the user wants to start and authenticate Tailscale
    echo "${Cyan}Do you want to start Tailscale and authenticate? (y/n)${Color_Off}"
    read -r tailscale_auth
    
    if [[ "$tailscale_auth" =~ ^[Yy]$ ]]; then
        echo "${Cyan}Starting Tailscale daemon...${Color_Off}"
        sudo systemctl enable --now tailscaled
        
        echo "${Cyan}Authenticating to Tailscale network...${Color_Off}"
        echo "${Purple}You will be prompted to authenticate in a browser.${Color_Off}"
        
        # Ask if the user wants to advertise as an exit node
        echo "${Cyan}Do you want to advertise this machine as an exit node? (y/n)${Color_Off}"
        read -r exit_node
        
        if [[ "$exit_node" =~ ^[Yy]$ ]]; then
            sudo tailscale up --advertise-exit-node
            echo "${Green}Tailscale started as an exit node. You can now authorize this exit node from the admin console.${Color_Off}"
        else
            sudo tailscale up
            echo "${Green}Tailscale started successfully.${Color_Off}"
        fi
        
        # Check Tailscale status
        echo "${Cyan}Checking Tailscale status...${Color_Off}"
        tailscale status
    else
        echo "${Yellow}Skipping Tailscale startup and authentication.${Color_Off}"
        echo "${Purple}You can manually start and authenticate later with: 'sudo tailscale up'${Color_Off}"
    fi
    
    echo "${Green}Tailscale installation completed.${Color_Off}"
    show_separator
}
