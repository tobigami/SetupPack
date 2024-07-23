#!/bin/bash
echo Start installing!
# sudo apt update

export Color_Off=$(tput sgr0) # Text Reset
export Red=$(tput setaf 1)    # Red
export Green=$(tput setaf 2)  # Green
export Yellow=$(tput setaf 3) # Yellow
export Purple=$(tput setaf 5) # Purple
export Cyan=$(tput setaf 6)   # Cyan

# nala
if ! command -v nala &>/dev/null; then
  echo "Installing nala package manager..."
  sudo apt install nala -y
else
  echo "Nala installed"
fi

# curl
if ! command -v curl &> /dev/null
then
    echo "Installing curl ..."
    # Cài đặt curl
    sudo apt install -y curl
else
    echo "Curl installed"
fi


# chrome
if ! command -v google-chrome &> /dev/null
then
    echo "Installing Google Chrome..."
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
else
    echo command -v google-chrome &> /dev/null
    echo "Google Chrome installed"
fi

# vscode
if ! command -v code &> /dev/null
then
    echo "Installing VSCode..."
    
    
    # Cài đặt các gói cần thiết để thêm kho lưu trữ
    sudo apt install -y software-properties-common apt-transport-https wget

    # Thêm kho lưu trữ chính thức của Microsoft
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
    # Cập nhật lại danh sách gói cài đặt
    sudo apt update
    sudo apt install -y code
else
    echo "VSCode installed"
fi

# Terminator
if ! command -v terminator &> /dev/null
then
    echo "Terminator installing.... "
    
    # Cập nhật danh sách gói cài đặt
    sudo apt update
    # Cài đặt Terminator
    sudo apt install -y terminator
else
    echo "Terminator installed"
fi

# nvm
if ! [[ -f ~/.nvm/nvm.sh ]];
then
    echo "Installing nvm..."
    
    # Tải và cài đặt nvm từ script chính thức
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    
    # Nạp nvm vào shell hiện tại
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
    echo "nvm installed"
fi

# Kiểm tra Spotify đã được cài đặt chưa
if ! snap list | grep -q spotify; then

    # Cài đặt snapd nếu chưa được cài đặt
    if ! command -v snap &> /dev/null; then
        sudo apt install -y snapd
    fi
    echo "Installing Shopify..."
    # Cài đặt Spotify thông qua Snap
    sudo snap install spotify
else
    echo "Spotify installed"
fi

#config time zone when use dual boot ubuntu and window
