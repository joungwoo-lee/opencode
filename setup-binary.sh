#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
ORANGE='\033[38;5;214m'
NC='\033[0m' # No Color
MUTED='\033[0;2m'

print_message() {
    local level=$1
    local message=$2
    local color=""

    case $level in
        info) color="${NC}" ;;
        warning) color="${NC}" ;;
        error) color="${RED}" ;;
    esac

    echo -e "${color}${message}${NC}"
}

# 1. Locate Binary
BINARY_NAME="opencode"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BINARY_PATH="$SCRIPT_DIR/$BINARY_NAME"

if [ ! -f "$BINARY_PATH" ]; then
    print_message error "Error: '$BINARY_NAME' file not found in current directory."
    print_message info "Please place the built '$BINARY_NAME' binary in the same folder as this script."
    exit 1
fi

# 2. Install
INSTALL_DIR="$HOME/.opencode/bin"
mkdir -p "$INSTALL_DIR"

print_message info "Installing binary..."
cp "$BINARY_PATH" "$INSTALL_DIR/$BINARY_NAME"
chmod 755 "$INSTALL_DIR/$BINARY_NAME"

# 3. Setup PATH
add_to_path() {
    local config_file=$1
    local command=$2

    if grep -Fxq "$command" "$config_file"; then
        print_message info "Command already exists in $config_file, skipping write."
    elif [[ -w $config_file ]]; then
        echo -e "\n# opencode" >> "$config_file"
        echo "$command" >> "$config_file"
        print_message info "${MUTED}Successfully added ${NC}opencode ${MUTED}to \$PATH in ${NC}$config_file"
    else
        print_message warning "Manually add the directory to $config_file (or similar):"
        print_message info "  $command"
    fi
}

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

current_shell=$(basename "$SHELL")
case $current_shell in
    fish)
        config_files="$HOME/.config/fish/config.fish"
    ;;
    zsh)
        config_files="$HOME/.zshrc $HOME/.zshenv $XDG_CONFIG_HOME/zsh/.zshrc $XDG_CONFIG_HOME/zsh/.zshenv"
    ;;
    bash)
        config_files="$HOME/.bashrc $HOME/.bash_profile $HOME/.profile $XDG_CONFIG_HOME/bash/.bashrc $XDG_CONFIG_HOME/bash/.bash_profile"
    ;;
    ash)
        config_files="$HOME/.ashrc $HOME/.profile /etc/profile"
    ;;
    sh)
        config_files="$HOME/.ashrc $HOME/.profile /etc/profile"
    ;;
    *)
        # Default case
        config_files="$HOME/.bashrc $HOME/.bash_profile $XDG_CONFIG_HOME/bash/.bashrc $XDG_CONFIG_HOME/bash/.bash_profile"
    ;;
esac

config_file=""
for file in $config_files; do
    if [[ -f $file ]]; then
        config_file=$file
        break
    fi
done

if [[ -z $config_file ]]; then
    print_message warning "No config file found for $current_shell. You may need to manually add to PATH:"
    print_message info "  export PATH=$INSTALL_DIR:\$PATH"
elif [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    case $current_shell in
        fish)
            add_to_path "$config_file" "fish_add_path $INSTALL_DIR"
        ;;
        zsh)
            add_to_path "$config_file" "export PATH=$INSTALL_DIR:\$PATH"
        ;;
        bash)
            add_to_path "$config_file" "export PATH=$INSTALL_DIR:\$PATH"
        ;;
        ash)
            add_to_path "$config_file" "export PATH=$INSTALL_DIR:\$PATH"
        ;;
        sh)
            add_to_path "$config_file" "export PATH=$INSTALL_DIR:\$PATH"
        ;;
        *)
            export PATH=$INSTALL_DIR:$PATH
            print_message warning "Manually add the directory to $config_file (or similar):"
            print_message info "  export PATH=$INSTALL_DIR:\$PATH"
        ;;
    esac
fi

echo -e ""
echo -e "${MUTED}Installation successful!${NC}"
echo -e "You can now use 'opencode' command."
echo -e "If it doesn't work, please restart your shell."
