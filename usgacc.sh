#!/bin/bash

# HCM SSO Login Script
# This script automates the initial login and stops at 2FA for manual completion

# Configuration file path
CONFIG_FILE="$HOME/.hcm_sso_config"
SSO_URL="https://hcm-sso.onehcm.usg.edu/"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to create config file
create_config() {
    echo -e "${YELLOW}Setting up credentials...${NC}"
    read -p "Enter username: " username
    read -s -p "Enter password: " password
    echo
    
    # Create config file with restricted permissions
    cat > "$CONFIG_FILE" << EOF
USERNAME="$username"
PASSWORD="$password"
EOF
    
    # Secure the config file
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}Credentials saved securely to $CONFIG_FILE${NC}"
}

# Function to load credentials
load_credentials() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Config file not found. Creating new one...${NC}"
        create_config
    fi
    
    source "$CONFIG_FILE"
    
    if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
        echo -e "${RED}Invalid credentials in config file. Please reconfigure.${NC}"
        create_config
        source "$CONFIG_FILE"
    fi
}

# Function to perform login
perform_login() {
    echo -e "${GREEN}Starting HCM SSO login process...${NC}"
    echo -e "${YELLOW}Opening browser and attempting login...${NC}"
    
    # Create a temporary AppleScript for browser automation
    cat > /tmp/hcm_login.scpt << EOF
tell application "Safari"
    activate
    make new document with properties {URL:"$SSO_URL"}
    delay 3
    
    -- Wait for page to load and try to fill login form
    repeat 10 times
        try
            do JavaScript "
                var usernameField = document.querySelector('input[name=\"username\"], input[name=\"user\"], input[name=\"email\"], input[type=\"email\"], input[id*=\"user\"], input[id*=\"login\"]');
                var passwordField = document.querySelector('input[type=\"password\"]');
                
                if (usernameField && passwordField) {
                    usernameField.value = '$USERNAME';
                    passwordField.value = '$PASSWORD';
                    
                    // Try to find and click submit button
                    var submitBtn = document.querySelector('button[type=\"submit\"], input[type=\"submit\"], button[id*=\"login\"], button[id*=\"submit\"]');
                    if (submitBtn) {
                        submitBtn.click();
                    }
                    'success';
                } else {
                    'waiting';
                }
            " in document 1
            delay 2
            exit repeat
        on error
            delay 1
        end try
    end repeat
end tell
EOF
    
    # Execute the AppleScript
    osascript /tmp/hcm_login.scpt
    
    # Clean up
    rm /tmp/hcm_login.scpt
    
    echo -e "${GREEN}Login form submitted!${NC}"
    echo -e "${YELLOW}Please complete 2FA authentication in your browser.${NC}"
}

# Function to use Chrome instead of Safari
perform_login_chrome() {
    echo -e "${GREEN}Starting HCM SSO login process with Chrome...${NC}"
    
    # Create Chrome automation script
    cat > /tmp/hcm_login_chrome.scpt << EOF
tell application "Google Chrome"
    activate
    make new window
    set URL of active tab of window 1 to "$SSO_URL"
    delay 3
    
    repeat 10 times
        try
            execute active tab of window 1 javascript "
                var usernameField = document.querySelector('input[name=\"username\"], input[name=\"user\"], input[name=\"email\"], input[type=\"email\"], input[id*=\"user\"], input[id*=\"login\"]');
                var passwordField = document.querySelector('input[type=\"password\"]');
                
                if (usernameField && passwordField) {
                    usernameField.value = '$USERNAME';
                    passwordField.value = '$PASSWORD';
                    
                    var submitBtn = document.querySelector('button[type=\"submit\"], input[type=\"submit\"], button[id*=\"login\"], button[id*=\"submit\"]');
                    if (submitBtn) {
                        submitBtn.click();
                    }
                    'success';
                } else {
                    'waiting';
                }
            "
            delay 2
            exit repeat
        on error
            delay 1
        end try
    end repeat
end tell
EOF
    
    osascript /tmp/hcm_login_chrome.scpt
    rm /tmp/hcm_login_chrome.scpt
    
    echo -e "${GREEN}Login form submitted!${NC}"
    echo -e "${YELLOW}Please complete 2FA authentication in your browser.${NC}"
}

# Main menu
show_menu() {
    echo -e "${GREEN}=== HCM SSO Login Script ===${NC}"
    echo "1. Login with Safari"
    echo "2. Login with Chrome"
    echo "3. Reconfigure credentials"
    echo "4. Delete stored credentials"
    echo "5. Exit"
    echo
    read -p "Choose an option (1-5): " choice
}

# Main execution
main() {
    while true; do
        show_menu
        
        case $choice in
            1)
                load_credentials
                perform_login
                ;;
            2)
                load_credentials
                perform_login_chrome
                ;;
            3)
                create_config
                ;;
            4)
                if [[ -f "$CONFIG_FILE" ]]; then
                    rm "$CONFIG_FILE"
                    echo -e "${GREEN}Credentials deleted.${NC}"
                else
                    echo -e "${YELLOW}No credentials file found.${NC}"
                fi
                ;;
            5)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
        echo
    done
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is designed for macOS. For Linux, you'll need to modify the browser automation parts.${NC}"
    exit 1
fi

# Run main function
main
