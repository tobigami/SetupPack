#!/bin/bash
echo Start installing!
# sudo apt update
# curl
if ! command -v curl &> /dev/null
then
    echo "curl chưa được cài đặt. Tiến hành cài đặt curl..."
    
    # Cài đặt curl
    sudo apt install -y curl
    
    echo "curl đã được cài đặt thành công."
else
    echo "Curl đã được cài đặt."
fi


# chrome
if ! command -v google-chrome &> /dev/null
then
    echo "Google Chrome chưa được cài đặt. Tiến hành cài đặt..."
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
else
    echo command -v google-chrome &> /dev/null
    echo "Google Chrome đã được cài đặt."
fi

# vscode
if ! command -v code &> /dev/null
then
    echo "VSCode chưa được cài đặt. Tiến hành cài đặt VSCode..."
    
    
    # Cài đặt các gói cần thiết để thêm kho lưu trữ
    sudo apt install -y software-properties-common apt-transport-https wget

    # Thêm kho lưu trữ chính thức của Microsoft
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
    
    # Cập nhật lại danh sách gói cài đặt
    sudo apt update

    sudo apt install -y code
    
    echo "VSCode đã được cài đặt thành công."
else
    echo "VSCode đã được cài đặt."
fi
