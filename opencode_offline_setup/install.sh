#!/bin/bash

# 설치 스크립트 (Linux)
# 사용법: sudo ./install.sh

set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="opencode"
SOURCE_BINARY="$SCRIPT_DIR/dist/opencode-linux-x64"

if [ ! -f "$SOURCE_BINARY" ]; then
    echo "Error: Binary file '$SOURCE_BINARY' not found."
    echo "Please make sure you have run the build_offline.sh script first and transferred the 'dist' folder."
    exit 1
fi

echo "Installing $BINARY_NAME to $INSTALL_DIR..."

# 바이너리 복사
if [ -w "$INSTALL_DIR" ]; then
    cp "$SOURCE_BINARY" "$INSTALL_DIR/$BINARY_NAME"
else
    echo "Requesting root permissions to copy to $INSTALL_DIR..."
    sudo cp "$SOURCE_BINARY" "$INSTALL_DIR/$BINARY_NAME"
fi

# 실행 권한 부여
if [ -w "$INSTALL_DIR/$BINARY_NAME" ]; then
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
else
    sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
fi

echo "Installation complete!"
echo "You can now use '$BINARY_NAME' command."
