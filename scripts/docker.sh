#!/bin/bash

# Source common functions and variables
source "$(dirname "$0")/common.sh"

# Function to install Docker
install_docker() {
    show_section "Docker"
    
    # Check if Docker is already installed
    if command -v docker &>/dev/null; then
        echo "${Yellow}Docker appears to be already installed.${Color_Off}"
        docker --version
    else
        echo "${Cyan}Docker not found. Installing Docker...${Color_Off}"
        
        # Install necessary packages
        echo "${Cyan}Installing dependencies...${Color_Off}"
        if command -v nala &>/dev/null; then
            sudo nala install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
        else
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
        fi
        
        # Add Docker's official GPG key
        echo "${Cyan}Adding Docker's official GPG key...${Color_Off}"
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        # Set up Docker repository
        echo "${Cyan}Setting up Docker repository...${Color_Off}"
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Update package index
        echo "${Cyan}Updating package index...${Color_Off}"
        if command -v nala &>/dev/null; then
            sudo nala update
        else
            sudo apt-get update
        fi
        
        # Install Docker Engine
        echo "${Cyan}Installing Docker Engine...${Color_Off}"
        if command -v nala &>/dev/null; then
            sudo nala install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
        else
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
        fi
        
        # Verify Docker installation
        if command -v docker &>/dev/null; then
            echo "${Green}Docker installed successfully.${Color_Off}"
            docker --version
        else
            echo "${Red}Failed to install Docker. Please check for errors.${Color_Off}"
            return 1
        fi
    fi
    
    # Configure Docker to run without sudo
    echo "${Cyan}Configuring Docker to run without sudo...${Color_Off}"
    
    # Create the docker group if it doesn't exist
    if ! getent group docker &>/dev/null; then
        echo "${Cyan}Creating docker group...${Color_Off}"
        sudo groupadd docker
    else
        echo "${Yellow}Docker group already exists.${Color_Off}"
    fi
    
    # Add current user to the docker group
    if ! groups $CURRENT_USER | grep -q docker; then
        echo "${Cyan}Adding user $CURRENT_USER to docker group...${Color_Off}"
        sudo usermod -aG docker $CURRENT_USER
        echo "${Green}User $CURRENT_USER added to docker group.${Color_Off}"
        echo "${Purple}You may need to log out and log back in, or run the following command to apply changes:${Color_Off}"
        echo "${Purple}newgrp docker${Color_Off}"
    else
        echo "${Yellow}User $CURRENT_USER is already in docker group.${Color_Off}"
    fi
    
    # Restart Docker service to apply changes
    echo "${Cyan}Restarting Docker service...${Color_Off}"
    sudo systemctl restart docker.service
    
    # Verify Docker can run without sudo
    echo "${Cyan}Verifying Docker can run without sudo...${Color_Off}"
    echo "${Purple}Note: If this is the first time adding your user to docker group, you may need to log out and log back in first.${Color_Off}"
    
    # Try to run Docker without sudo, but don't make it an error if it fails
    echo "${Cyan}Attempting to run 'docker info' as current user...${Color_Off}"
    if docker info &>/dev/null; then
        echo "${Green}Success! Docker is configured to run without sudo.${Color_Off}"
    else
        echo "${Yellow}Docker command failed as current user. You may need to log out and log back in.${Color_Off}"
        echo "${Yellow}To temporarily apply changes without logging out, run: ${Purple}newgrp docker${Color_Off}"
    fi
    
    # Install Docker Compose
    echo "${Cyan}Installing Docker Compose...${Color_Off}"
    if ! command -v docker-compose &>/dev/null; then
        echo "${Cyan}Docker Compose not found. Installing...${Color_Off}"
        # Install docker-compose from package manager
        if command -v nala &>/dev/null; then
            sudo nala install -y docker-compose
        else
            sudo apt-get install -y docker-compose
        fi
        
        if command -v docker-compose &>/dev/null; then
            echo "${Green}Docker Compose installed successfully.${Color_Off}"
            docker-compose --version
        else
            echo "${Yellow}Could not install Docker Compose from package manager. Trying alternative method...${Color_Off}"
            
            # Define the latest Docker Compose version to install
            DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
            
            # If we couldn't get the latest version, use a known stable version
            if [ -z "$DOCKER_COMPOSE_VERSION" ]; then
                DOCKER_COMPOSE_VERSION="v2.18.1"
                echo "${Yellow}Could not determine latest Docker Compose version, using $DOCKER_COMPOSE_VERSION${Color_Off}"
            fi
            
            # Download and install Docker Compose
            sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            
            if command -v docker-compose &>/dev/null; then
                echo "${Green}Docker Compose installed successfully via direct download.${Color_Off}"
                docker-compose --version
            else
                echo "${Red}Failed to install Docker Compose. Please check for errors.${Color_Off}"
            fi
        fi
    else
        echo "${Yellow}Docker Compose is already installed.${Color_Off}"
        docker-compose --version
    fi
    
    echo "${Green}Docker installation and configuration completed.${Color_Off}"
    show_separator
}
