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

# 1. Check Bun
if ! command -v bun >/dev/null 2>&1; then
    print_message error "Error: Bun is not installed. Please install Bun first."
    exit 1
fi

# 2. Locate project
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# SCRIPT_DIR is opencode_offline_setup, so workspace is one level up
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
OPENCODE_PKG_DIR="$WORKSPACE_DIR/packages/opencode"

if [ ! -d "$OPENCODE_PKG_DIR" ]; then
    print_message error "Error: Cannot find packages/opencode directory."
    exit 1
fi

# 3. Install dependencies
print_message info "Installing dependencies..."
cd "$WORKSPACE_DIR"
bun install

# 4. Build
print_message info "Building opencode..."
cd "$OPENCODE_PKG_DIR"
# Use --single to build for current platform only
bun run script/build.ts --single

# 5. Find built binary
# Detect system properties to choose the right binary
raw_os=$(uname -s)
os=$(echo "$raw_os" | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)

if [[ "$arch" == "aarch64" ]]; then arch="arm64"; fi
if [[ "$arch" == "x86_64" ]]; then arch="x64"; fi

is_musl=false
if [ "$os" = "linux" ]; then
    if [ -f /etc/alpine-release ]; then
        is_musl=true
    fi
    if command -v ldd >/dev/null 2>&1; then
        if ldd --version 2>&1 | grep -qi musl; then
            is_musl=true
        fi
    fi
fi

# Construct expected directory name pattern
# Format in build.ts: opencode-<os>-<arch>[-baseline][-musl]
# We prefer the standard version (no baseline) if possible.

TARGET_NAME="opencode-$os-$arch"

if [ "$is_musl" = "true" ]; then
    TARGET_NAME="$TARGET_NAME-musl"
fi

# Try to find exact match
BUILD_DIR="$OPENCODE_PKG_DIR/dist/$TARGET_NAME"

# If not found, look for alternatives (e.g. maybe baseline was built?)
if [ ! -d "$BUILD_DIR" ]; then
    print_message warning "Preferred build directory $TARGET_NAME not found. Searching for alternatives..."
    # If we wanted non-musl but only have musl, or vice versa, or baseline
    # Just pick the first one that matches os and arch
    BUILD_DIR=$(find dist -mindepth 1 -maxdepth 1 -type d -name "opencode-$os-$arch*" | head -n 1)
fi


if [ -z "$BUILD_DIR" ] || [ ! -f "$BUILD_DIR/bin/opencode" ]; then
    print_message error "Error: Build failed or binary not found in dist/"
    exit 1
fi

# 6. Install
INSTALL_DIR="$HOME/.opencode/bin"
mkdir -p "$INSTALL_DIR"

print_message info "Installing binary from $BUILD_DIR/bin/opencode to $INSTALL_DIR..."
cp "$BUILD_DIR/bin/opencode" "$INSTALL_DIR/opencode"
chmod 755 "$INSTALL_DIR/opencode"

# 7. Setup PATH (Taken from original install script)
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

if [ -n "${GITHUB_ACTIONS-}" ] && [ "${GITHUB_ACTIONS}" == "true" ]; then
    echo "$INSTALL_DIR" >> $GITHUB_PATH
    print_message info "Added $INSTALL_DIR to \$GITHUB_PATH"
fi

echo -e ""
echo -e "${MUTED}Installation successful!${NC}"
echo -e "You can now use 'opencode' command."
echo -e "If it doesn't work, please restart your shell."
