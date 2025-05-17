#!/bin/bash

# Source common functions and variables
source "$(dirname "$0")/common.sh"

# Function to install Postman
install_postman() {
    show_section "Postman"
    
    if command -v postman &> /dev/null; then
        echo "${Yellow}Postman is already installed.${Color_Off}"
    else
        echo "${Cyan}Installing Postman...${Color_Off}"
        
        # Create installation directory
        POSTMAN_DIR="$HOME/.local/share/Postman"
        mkdir -p "$POSTMAN_DIR"
        
        # Create temp directory for download
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR" || exit
        
        # Download Postman
        echo "${Cyan}Downloading Postman...${Color_Off}"
        POSTMAN_URL="https://dl.pstmn.io/download/latest/linux64"
        wget -q --show-progress "$POSTMAN_URL" -O postman.tar.gz
        
        if [ -f postman.tar.gz ]; then
            echo "${Green}Download completed.${Color_Off}"
            
            # Extract Postman
            echo "${Cyan}Extracting Postman...${Color_Off}"
            tar -xzf postman.tar.gz
            
            if [ -d "Postman" ]; then
                # Move Postman to installation directory
                echo "${Cyan}Installing Postman to $POSTMAN_DIR...${Color_Off}"
                cp -r Postman/* "$POSTMAN_DIR"
                
                # Create desktop entry
                echo "${Cyan}Creating desktop entry and launcher script...${Color_Off}"
                
                # Create a launcher script in /usr/local/bin
                echo "#!/bin/bash" | sudo tee /usr/local/bin/postman > /dev/null
                echo "\"$POSTMAN_DIR/Postman\"" | sudo tee -a /usr/local/bin/postman > /dev/null
                sudo chmod +x /usr/local/bin/postman
                
                # Create desktop entry
                cat > "$HOME/.local/share/applications/postman.desktop" << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Postman
Icon=$POSTMAN_DIR/app/resources/app/assets/icon.png
Exec="$POSTMAN_DIR/Postman" %f
Comment=API Development Environment
Categories=Development;Utility;
Terminal=false
StartupWMClass=postman
EOL
                
                echo "${Green}Postman installed successfully. You can start it by typing 'postman' or from your application menu.${Color_Off}"
            else
                echo "${Red}Failed to extract Postman. Installation aborted.${Color_Off}"
            fi
        else
            echo "${Red}Failed to download Postman. Please check your internet connection.${Color_Off}"
        fi
        
        # Clean up
        cd - > /dev/null || exit
        rm -rf "$TEMP_DIR"
    fi
    show_separator
}

# If this script is run directly, call the install function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_postman
fi
