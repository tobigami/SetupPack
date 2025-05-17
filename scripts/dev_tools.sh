#!/bin/bash

# Source common functions and variables
source "$(dirname "$0")/common.sh"

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

# Function to install NVM (Node Version Manager)
install_nvm() {
    show_section "NVM (Node Version Manager)"
    NVM_DIR="$HOME/.nvm"
    
    # Check explicitly for nvm.sh to determine if NVM structure is there
    if ! [ -s "$NVM_DIR/nvm.sh" ]; then # -s checks if file exists and is not empty
        echo "NVM not found. Installing latest version of NVM..."
        # Get the latest NVM version dynamically from GitHub
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
        echo "${Green}NVM installation script downloaded and executed.${Color_Off}"
        echo "${Purple}NVM requires sourcing its script. Attempting to source for current session...${Color_Off}"
        
        if [ -s "$NVM_DIR/nvm.sh" ]; then
            # shellcheck source=/dev/null
            \. "$NVM_DIR/nvm.sh" # Source NVM
            if command -v nvm &>/dev/null; then
                echo "${Green}NVM sourced successfully for the current session.${Color_Off}"
                
                # Install latest LTS version of Node.js
                echo "${Cyan}Installing latest LTS version of Node.js...${Color_Off}"
                nvm install --lts
                nvm use --lts
                NODE_VERSION=$(node -v)
                echo "${Green}Node.js ${NODE_VERSION} (LTS) installed and set as default.${Color_Off}"
                
                # Install global npm packages
                echo "${Cyan}Installing global npm packages: pm2, yarn, pnpm...${Color_Off}"
                npm install -g pm2 yarn pnpm
                
                # Verify installations
                if command -v pm2 &>/dev/null && command -v yarn &>/dev/null && command -v pnpm &>/dev/null; then
                    echo "${Green}Global packages installed successfully:${Color_Off}"
                    echo "PM2: $(pm2 -v 2>/dev/null || echo 'version check failed')"
                    echo "Yarn: $(yarn -v 2>/dev/null || echo 'version check failed')"
                    echo "PNPM: $(pnpm -v 2>/dev/null || echo 'version check failed')"
                else
                    echo "${Yellow}Some global packages may not have installed correctly. Please check manually.${Color_Off}"
                fi
                
                # Ensure NVM is properly added to shell config files
                echo "${Cyan}Ensuring NVM initialization in shell config files...${Color_Off}"
                # Function to add NVM config to a shell config file if not already there
                add_nvm_to_shell_config() {
                    local config_file="$1"
                    if [ -f "$config_file" ]; then
                        if ! grep -q "NVM_DIR=\"\$HOME/.nvm\"" "$config_file"; then
                            echo "${Cyan}Adding NVM configuration to $config_file...${Color_Off}"
                            echo '' >> "$config_file"
                            echo '# NVM Configuration' >> "$config_file"
                            echo 'export NVM_DIR="$HOME/.nvm"' >> "$config_file"
                            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> "$config_file"
                            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> "$config_file"
                            return 0
                        else
                            echo "${Yellow}NVM configuration already exists in $config_file.${Color_Off}"
                            return 1
                        fi
                    else
                        echo "${Yellow}$config_file does not exist. Skipping.${Color_Off}"
                        return 2
                    fi
                }
                
                # Check and add to multiple possible config files
                CHANGES_MADE=false
                
                # Bash configs
                if add_nvm_to_shell_config "$HOME/.bashrc"; then
                    CHANGES_MADE=true
                fi
                
                if add_nvm_to_shell_config "$HOME/.bash_profile"; then
                    CHANGES_MADE=true
                fi
                
                # Zsh configs
                if add_nvm_to_shell_config "$HOME/.zshrc"; then
                    CHANGES_MADE=true
                fi
                
                if add_nvm_to_shell_config "$HOME/.zprofile"; then
                    CHANGES_MADE=true
                fi
                
                if [ "$CHANGES_MADE" = true ]; then
                    echo "${Green}NVM configuration added to shell config files.${Color_Off}"
                    echo "${Purple}The changes will take effect in new terminal sessions.${Color_Off}"
                else
                    echo "${Yellow}No changes were made to shell config files. NVM configuration might already exist.${Color_Off}"
                fi
            else
                echo "${Yellow}NVM command not found after sourcing. Manual sourcing or new terminal may be needed.${Color_Off}"
            fi
            echo "${Purple}To use NVM in new terminals, ensure '$NVM_DIR/nvm.sh' is sourced in your shell profile (e.g., ~/.bashrc or ~/.zshrc).${Color_Off}"
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
                    
                    # Check if Node.js is installed
                    if ! command -v node &>/dev/null; then
                        echo "${Cyan}Node.js not found. Installing latest LTS version...${Color_Off}"
                        nvm install --lts
                        nvm use --lts
                        NODE_VERSION=$(node -v)
                        echo "${Green}Node.js ${NODE_VERSION} (LTS) installed and set as default.${Color_Off}"
                    else
                        NODE_VERSION=$(node -v)
                        echo "${Yellow}Node.js ${NODE_VERSION} is already installed.${Color_Off}"
                    fi
                    
                    # Check and install global packages if needed
                    echo "${Cyan}Checking for global npm packages...${Color_Off}"
                    MISSING_PACKAGES=()
                    
                    if ! command -v pm2 &>/dev/null; then
                        MISSING_PACKAGES+=("pm2")
                    fi
                    
                    if ! command -v yarn &>/dev/null; then
                        MISSING_PACKAGES+=("yarn")
                    fi
                    
                    if ! command -v pnpm &>/dev/null; then
                        MISSING_PACKAGES+=("pnpm")
                    fi
                    
                    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
                        echo "${Cyan}Installing missing global packages: ${MISSING_PACKAGES[*]}...${Color_Off}"
                        npm install -g "${MISSING_PACKAGES[@]}"
                        echo "${Green}Global packages installed.${Color_Off}"
                    else
                        echo "${Yellow}All required global packages are already installed.${Color_Off}"
                    fi
                    
                    # Display versions
                    echo "${Green}Installed versions:${Color_Off}"
                    echo "Node.js: $(node -v 2>/dev/null || echo 'not installed')"
                    echo "NPM: $(npm -v 2>/dev/null || echo 'not installed')"
                    echo "PM2: $(pm2 -v 2>/dev/null || echo 'not installed')"
                    echo "Yarn: $(yarn -v 2>/dev/null || echo 'not installed')"
                    echo "PNPM: $(pnpm -v 2>/dev/null || echo 'not installed')"
                    
                    # Ensure NVM is properly added to shell config files
                    echo "${Cyan}Ensuring NVM initialization in shell config files...${Color_Off}"
                    # Function to add NVM config to a shell config file if not already there
                    add_nvm_to_shell_config() {
                        local config_file="$1"
                        if [ -f "$config_file" ]; then
                            if ! grep -q "NVM_DIR=\"\$HOME/.nvm\"" "$config_file"; then
                                echo "${Cyan}Adding NVM configuration to $config_file...${Color_Off}"
                                echo '' >> "$config_file"
                                echo '# NVM Configuration' >> "$config_file"
                                echo 'export NVM_DIR="$HOME/.nvm"' >> "$config_file"
                                echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> "$config_file"
                                echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> "$config_file"
                                return 0
                            else
                                echo "${Yellow}NVM configuration already exists in $config_file.${Color_Off}"
                                return 1
                            fi
                        else
                            echo "${Yellow}$config_file does not exist. Skipping.${Color_Off}"
                            return 2
                        fi
                    }
                    
                    # Check and add to multiple possible config files
                    CHANGES_MADE=false
                    
                    # Bash configs
                    if add_nvm_to_shell_config "$HOME/.bashrc"; then
                        CHANGES_MADE=true
                    fi
                    
                    if add_nvm_to_shell_config "$HOME/.bash_profile"; then
                        CHANGES_MADE=true
                    fi
                    
                    # Zsh configs
                    if add_nvm_to_shell_config "$HOME/.zshrc"; then
                        CHANGES_MADE=true
                    fi
                    
                    if add_nvm_to_shell_config "$HOME/.zprofile"; then
                        CHANGES_MADE=true
                    fi
                    
                    if [ "$CHANGES_MADE" = true ]; then
                        echo "${Green}NVM configuration added to shell config files.${Color_Off}"
                        echo "${Purple}The changes will take effect in new terminal sessions.${Color_Off}"
                    else
                        echo "${Yellow}No changes were made to shell config files. NVM configuration might already exist.${Color_Off}"
                    fi
                else
                    echo "${Yellow}Failed to source NVM. Manual sourcing or new terminal may be needed.${Color_Off}"
                fi
            else
                echo "${Red}NVM script $NVM_DIR/nvm.sh not found or empty. Cannot source.${Color_Off}"
            fi
        else
            echo "${Green}NVM command is already available.${Color_Off}"
            
            # Check if Node.js is installed
            if ! command -v node &>/dev/null; then
                echo "${Cyan}Node.js not found. Installing latest LTS version...${Color_Off}"
                nvm install --lts
                nvm use --lts
                NODE_VERSION=$(node -v)
                echo "${Green}Node.js ${NODE_VERSION} (LTS) installed and set as default.${Color_Off}"
            else
                NODE_VERSION=$(node -v)
                echo "${Yellow}Node.js ${NODE_VERSION} is already installed.${Color_Off}"
            fi
            
            # Check and install global packages if needed
            echo "${Cyan}Checking for global npm packages...${Color_Off}"
            MISSING_PACKAGES=()
            
            if ! command -v pm2 &>/dev/null; then
                MISSING_PACKAGES+=("pm2")
            fi
            
            if ! command -v yarn &>/dev/null; then
                MISSING_PACKAGES+=("yarn")
            fi
            
            if ! command -v pnpm &>/dev/null; then
                MISSING_PACKAGES+=("pnpm")
            fi
            
            if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
                echo "${Cyan}Installing missing global packages: ${MISSING_PACKAGES[*]}...${Color_Off}"
                npm install -g "${MISSING_PACKAGES[@]}"
                echo "${Green}Global packages installed.${Color_Off}"
            else
                echo "${Yellow}All required global packages are already installed.${Color_Off}"
            fi
            
            # Display versions
            echo "${Green}Installed versions:${Color_Off}"
            echo "Node.js: $(node -v 2>/dev/null || echo 'not installed')"
            echo "NPM: $(npm -v 2>/dev/null || echo 'not installed')"
            echo "PM2: $(pm2 -v 2>/dev/null || echo 'not installed')"
            echo "Yarn: $(yarn -v 2>/dev/null || echo 'not installed')"
            echo "PNPM: $(pnpm -v 2>/dev/null || echo 'not installed')"
            
            # Ensure NVM is properly added to shell config files
            echo "${Cyan}Ensuring NVM initialization in shell config files...${Color_Off}"
            # Function to add NVM config to a shell config file if not already there
            add_nvm_to_shell_config() {
                local config_file="$1"
                if [ -f "$config_file" ]; then
                    if ! grep -q "NVM_DIR=\"\$HOME/.nvm\"" "$config_file"; then
                        echo "${Cyan}Adding NVM configuration to $config_file...${Color_Off}"
                        echo '' >> "$config_file"
                        echo '# NVM Configuration' >> "$config_file"
                        echo 'export NVM_DIR="$HOME/.nvm"' >> "$config_file"
                        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> "$config_file"
                        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> "$config_file"
                        return 0
                    else
                        echo "${Yellow}NVM configuration already exists in $config_file.${Color_Off}"
                        return 1
                    fi
                else
                    echo "${Yellow}$config_file does not exist. Skipping.${Color_Off}"
                    return 2
                fi
            }
            
            # Check and add to multiple possible config files
            CHANGES_MADE=false
            
            # Bash configs
            if add_nvm_to_shell_config "$HOME/.bashrc"; then
                CHANGES_MADE=true
            fi
            
            if add_nvm_to_shell_config "$HOME/.bash_profile"; then
                CHANGES_MADE=true
            fi
            
            # Zsh configs
            if add_nvm_to_shell_config "$HOME/.zshrc"; then
                CHANGES_MADE=true
            fi
            
            if add_nvm_to_shell_config "$HOME/.zprofile"; then
                CHANGES_MADE=true
            fi
            
            if [ "$CHANGES_MADE" = true ]; then
                echo "${Green}NVM configuration added to shell config files.${Color_Off}"
                echo "${Purple}The changes will take effect in new terminal sessions.${Color_Off}"
            else
                echo "${Yellow}No changes were made to shell config files. NVM configuration might already exist.${Color_Off}"
            fi
        fi
    fi
    show_separator
}
