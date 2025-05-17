#!/bin/bash

# Source common functions and variables
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/common.sh"

# Function to install JetBrains DataGrip
install_datagrip() {
    show_section "JetBrains DataGrip"
    
    # Install necessary compression/decompression packages if not already installed
    echo "${Cyan}Installing necessary compression utilities...${Color_Off}"
    sudo apt-get update
    sudo apt-get install -y tar gzip zip unzip p7zip-full bzip2 xz-utils
    
    # Try to install rar/unrar if available
    if apt-cache search unrar | grep -q "unrar"; then
        sudo apt-get install -y unrar
    elif apt-cache search rar | grep -q "rar"; then
        sudo apt-get install -y rar
    fi
    
    # Define DataGrip directory and download path
    DATAGRIP_DIR="$HOME/.local/share/JetBrains/DataGrip"
    DOWNLOAD_PATH="/tmp/datagrip.tar.gz"
    
    # Check if DataGrip is already installed
    if [ -d "$DATAGRIP_DIR" ] && command -v datagrip &>/dev/null; then
        echo "${Yellow}DataGrip appears to be already installed.${Color_Off}"
        datagrip --version 2>/dev/null || echo "${Yellow}Could not determine DataGrip version.${Color_Off}"
    else
        echo "${Cyan}DataGrip not found. Installing DataGrip...${Color_Off}"
        
        # Download latest DataGrip
        echo "${Cyan}Downloading latest version of DataGrip...${Color_Off}"
        # Current stable version URL - manually updated for reliability
        DOWNLOAD_URL="https://download.jetbrains.com/datagrip/datagrip-2023.3.4.tar.gz"
        echo "${Cyan}Downloading from: $DOWNLOAD_URL${Color_Off}"
        wget "$DOWNLOAD_URL" -O "$DOWNLOAD_PATH" --progress=bar:force
        
        # Check if download was successful
        if [ ! -f "$DOWNLOAD_PATH" ] || [ ! -s "$DOWNLOAD_PATH" ]; then
            echo "${Red}Download failed or file is empty. Trying alternative download method...${Color_Off}"
            curl -L "$DOWNLOAD_URL" -o "$DOWNLOAD_PATH"
        fi
        
        if [ -f "$DOWNLOAD_PATH" ]; then
            echo "${Green}Download completed successfully.${Color_Off}"
            
            # Create installation directory
            mkdir -p "$DATAGRIP_DIR"
            
            # Extract the downloaded archive
            echo "${Cyan}Extracting DataGrip...${Color_Off}"
            mkdir -p /tmp/datagrip_extract
            
            # Verbose extraction to see any potential errors
            tar -xzvf "$DOWNLOAD_PATH" -C "/tmp/datagrip_extract"
            EXTRACTION_STATUS=$?
            
            if [ $EXTRACTION_STATUS -ne 0 ]; then
                echo "${Red}Error extracting archive. Trying alternative method...${Color_Off}"
                # Alternative extraction method
                7z x "$DOWNLOAD_PATH" -o/tmp/datagrip_extract
                EXTRACTION_STATUS=$?
            fi
            
            # Find the extracted directory
            EXTRACTED_DIR=$(find /tmp/datagrip_extract -maxdepth 1 -name "DataGrip-*" -type d | head -n 1)
            
            if [ -d "$EXTRACTED_DIR" ]; then
                # Move DataGrip files to installation directory
                echo "${Cyan}Installing DataGrip to $DATAGRIP_DIR...${Color_Off}"
                cp -r "$EXTRACTED_DIR"/* "$DATAGRIP_DIR"
                
                # Create desktop entry and launcher script
                echo "${Cyan}Creating desktop entry and launcher script...${Color_Off}"
                
                # Find the exact bin directory
                BIN_DIR=$(find "$DATAGRIP_DIR" -name "bin" -type d | head -n 1)
                
                if [ -d "$BIN_DIR" ]; then
                    # Create a launcher script in /usr/local/bin
                    echo "#!/bin/bash" | sudo tee /usr/local/bin/datagrip > /dev/null
                    echo "\"$BIN_DIR/datagrip.sh\" \"\$@\"" | sudo tee -a /usr/local/bin/datagrip > /dev/null
                    sudo chmod +x /usr/local/bin/datagrip
                    
                    # Create desktop entry
                    cat > "$HOME/.local/share/applications/datagrip.desktop" << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=DataGrip
Icon=$BIN_DIR/datagrip.svg
Exec="$BIN_DIR/datagrip.sh" %f
Comment=A powerful IDE for SQL from JetBrains
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-datagrip
EOL
                    
                    # Clean up
                    echo "${Cyan}Cleaning up...${Color_Off}"
                    rm -rf "$DOWNLOAD_PATH" "/tmp/datagrip_extract"
                    
                    # Verify installation
                    if command -v datagrip &>/dev/null; then
                        echo "${Green}DataGrip installed successfully. You can start it by typing 'datagrip' or from your application menu.${Color_Off}"
                    else
                        echo "${Yellow}DataGrip installation completed, but the command 'datagrip' might not be in your PATH.${Color_Off}"
                        echo "${Yellow}You can still start DataGrip from $BIN_DIR/datagrip.sh${Color_Off}"
                    fi
                else
                    echo "${Red}Could not find the bin directory in the extracted files.${Color_Off}"
                    echo "${Yellow}DataGrip installation failed.${Color_Off}"
                fi
            else
                echo "${Red}Failed to extract DataGrip. Installation aborted.${Color_Off}"
                echo "${Yellow}Error details: Extraction status code = $EXTRACTION_STATUS${Color_Off}"
                echo "${Yellow}Please make sure all necessary decompression tools are installed.${Color_Off}"
            fi
        else
            echo "${Red}Failed to download DataGrip. Please check your internet connection or the download URL.${Color_Off}"
        fi
    fi
    
    # Provide information about the Toolbox App as an alternative
    echo "${Purple}NOTE: JetBrains recommends installing DataGrip using the JetBrains Toolbox App${Color_Off}"
    echo "${Purple}for easier updates and management. Consider installing it from:${Color_Off}"
    echo "${Purple}https://www.jetbrains.com/toolbox-app/${Color_Off}"
    
    show_separator
}

# Function to install JetBrains WebStorm
install_webstorm() {
    show_section "JetBrains WebStorm"
    
    # Install necessary compression/decompression packages if not already installed
    echo "${Cyan}Installing necessary compression utilities...${Color_Off}"
    sudo apt-get update
    sudo apt-get install -y tar gzip zip unzip p7zip-full bzip2 xz-utils
    
    # Try to install rar/unrar if available
    if apt-cache search unrar | grep -q "unrar"; then
        sudo apt-get install -y unrar
    elif apt-cache search rar | grep -q "rar"; then
        sudo apt-get install -y rar
    fi
    
    # Define WebStorm directory and download path
    WEBSTORM_DIR="$HOME/.local/share/JetBrains/WebStorm"
    DOWNLOAD_PATH="/tmp/webstorm.tar.gz"
    
    # Check if WebStorm is already installed
    if [ -d "$WEBSTORM_DIR" ] && command -v webstorm &>/dev/null; then
        echo "${Yellow}WebStorm appears to be already installed.${Color_Off}"
        webstorm --version 2>/dev/null || echo "${Yellow}Could not determine WebStorm version.${Color_Off}"
    else
        echo "${Cyan}WebStorm not found. Installing WebStorm...${Color_Off}"
        
        # Download latest WebStorm
        echo "${Cyan}Downloading latest version of WebStorm...${Color_Off}"
        # Current stable version URL - manually updated for reliability
        DOWNLOAD_URL="https://download.jetbrains.com/webstorm/WebStorm-2023.3.5.tar.gz"
        echo "${Cyan}Downloading from: $DOWNLOAD_URL${Color_Off}"
        wget "$DOWNLOAD_URL" -O "$DOWNLOAD_PATH" --progress=bar:force
        
        # Check if download was successful
        if [ ! -f "$DOWNLOAD_PATH" ] || [ ! -s "$DOWNLOAD_PATH" ]; then
            echo "${Red}Download failed or file is empty. Trying alternative download method...${Color_Off}"
            curl -L "$DOWNLOAD_URL" -o "$DOWNLOAD_PATH"
        fi
        
        if [ -f "$DOWNLOAD_PATH" ]; then
            echo "${Green}Download completed successfully.${Color_Off}"
            
            # Create installation directory
            mkdir -p "$WEBSTORM_DIR"
            
            # Extract the downloaded archive
            echo "${Cyan}Extracting WebStorm...${Color_Off}"
            mkdir -p /tmp/webstorm_extract
            
            # Verbose extraction to see any potential errors
            tar -xzvf "$DOWNLOAD_PATH" -C "/tmp/webstorm_extract"
            EXTRACTION_STATUS=$?
            
            if [ $EXTRACTION_STATUS -ne 0 ]; then
                echo "${Red}Error extracting archive. Trying alternative method...${Color_Off}"
                # Alternative extraction method
                7z x "$DOWNLOAD_PATH" -o/tmp/webstorm_extract
                EXTRACTION_STATUS=$?
            fi
            
            # Find the extracted directory
            EXTRACTED_DIR=$(find /tmp/webstorm_extract -maxdepth 1 -name "WebStorm-*" -type d | head -n 1)
            
            if [ -d "$EXTRACTED_DIR" ]; then
                # Move WebStorm files to installation directory
                echo "${Cyan}Installing WebStorm to $WEBSTORM_DIR...${Color_Off}"
                cp -r "$EXTRACTED_DIR"/* "$WEBSTORM_DIR"
                
                # Create desktop entry and launcher script
                echo "${Cyan}Creating desktop entry and launcher script...${Color_Off}"
                
                # Find the exact bin directory
                BIN_DIR=$(find "$WEBSTORM_DIR" -name "bin" -type d | head -n 1)
                
                if [ -d "$BIN_DIR" ]; then
                    # Create a launcher script in /usr/local/bin
                    echo "#!/bin/bash" | sudo tee /usr/local/bin/webstorm > /dev/null
                    echo "\"$BIN_DIR/webstorm.sh\" \"\$@\"" | sudo tee -a /usr/local/bin/webstorm > /dev/null
                    sudo chmod +x /usr/local/bin/webstorm
                    
                    # Create desktop entry
                    cat > "$HOME/.local/share/applications/webstorm.desktop" << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=WebStorm
Icon=$BIN_DIR/webstorm.svg
Exec="$BIN_DIR/webstorm.sh" %f
Comment=A powerful IDE for modern JavaScript development from JetBrains
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-webstorm
EOL
                    
                    # Clean up
                    echo "${Cyan}Cleaning up...${Color_Off}"
                    rm -rf "$DOWNLOAD_PATH" "/tmp/webstorm_extract"
                    
                    # Verify installation
                    if command -v webstorm &>/dev/null; then
                        echo "${Green}WebStorm installed successfully. You can start it by typing 'webstorm' or from your application menu.${Color_Off}"
                    else
                        echo "${Yellow}WebStorm installation completed, but the command 'webstorm' might not be in your PATH.${Color_Off}"
                        echo "${Yellow}You can still start WebStorm from $BIN_DIR/webstorm.sh${Color_Off}"
                    fi
                else
                    echo "${Red}Could not find the bin directory in the extracted files.${Color_Off}"
                    echo "${Yellow}WebStorm installation failed.${Color_Off}"
                fi
            else
                echo "${Red}Failed to extract WebStorm. Installation aborted.${Color_Off}"
                echo "${Yellow}Error details: Extraction status code = $EXTRACTION_STATUS${Color_Off}"
                echo "${Yellow}Please make sure all necessary decompression tools are installed.${Color_Off}"
            fi
        else
            echo "${Red}Failed to download WebStorm. Please check your internet connection or the download URL.${Color_Off}"
        fi
    fi
    
    # Provide information about the Toolbox App as an alternative
    echo "${Purple}NOTE: JetBrains recommends installing WebStorm using the JetBrains Toolbox App${Color_Off}"
    echo "${Purple}for easier updates and management. Consider installing it from:${Color_Off}"
    echo "${Purple}https://www.jetbrains.com/toolbox-app/${Color_Off}"
    
    show_separator
}

# If this script is run directly, call the install function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Please specify which JetBrains IDE to install: datagrip or webstorm"
    echo "Usage: $0 [datagrip|webstorm|all]"
    
    if [ -z "$1" ]; then
        # If no argument is provided, prompt user
        read -p "Enter your choice (datagrip/webstorm/all): " choice
    else
        choice="$1"
    fi
    
    case "$choice" in
        datagrip)
            install_datagrip
            ;;
        webstorm)
            install_webstorm
            ;;
        all)
            install_datagrip
            install_webstorm
            ;;
        *)
            echo "Invalid option. Please choose datagrip, webstorm, or all."
            exit 1
            ;;
    esac
fi
