#!/bin/bash

# Set the scripts directory and source common functions
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")/scripts"
source "$SCRIPT_DIR/common.sh"

# Source all module scripts
source "$SCRIPT_DIR/system_config.sh"
source "$SCRIPT_DIR/dev_tools.sh"
source "$SCRIPT_DIR/install_apps.sh"
source "$SCRIPT_DIR/docker.sh"

# Main function to run the script with arguments
main() {
    # Only display the header when running the script
    show_header

    # If no arguments, run everything
    if [ $# -eq 0 ] || [ "$1" = "all" ]; then
        setup_git_config
        setup_passwordless_sudo
        install_nala
        install_core_packages
        setup_git
        install_chrome
        install_vscode
        install_nvm
        install_spotify
        install_cascadia_font
        install_docker
        fix_timezone
        show_completion
        exit 0
    fi

    # Check for help argument
    if [[ "$1" = "help" || "$1" = "--help" || "$1" = "-h" ]]; then
        show_usage
        exit 0
    fi

    # Process specific installation options
    for option in "$@"; do
        case "$option" in
            sudo)
                setup_git_config  # We need the username for sudo
                setup_passwordless_sudo
                ;;
            nala)
                install_nala
                ;;
            core)
                install_core_packages
                ;;
            git)
                setup_git_config
                setup_git
                ;;
            chrome)
                install_chrome
                ;;
            vscode)
                install_vscode
                ;;
            nvm)
                install_nvm
                ;;
            spotify)
                install_spotify
                ;;
            font)
                install_cascadia_font
                ;;
            timezone)
                fix_timezone
                ;;
            docker)
                install_docker
                ;;
            *)
                echo "${Red}Unknown option: $option${Color_Off}"
                show_usage
                exit 1
                ;;
        esac
    done

    show_completion
}

# Run the main function with all arguments
main "$@"
