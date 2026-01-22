#!/bin/bash
set -e

# 스크립트 위치 확인
SCRIPT_DIR=$(dirname "$(realpath "$0")")
WORKSPACE_DIR="$SCRIPT_DIR/.."
OPENCODE_PKG_DIR="$WORKSPACE_DIR/packages/opencode"
OUTPUT_DIR="$SCRIPT_DIR/dist"

echo "Build starting using existing build script..."
echo "Target directory: $OPENCODE_PKG_DIR"

# 출력 디렉토리 초기화
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 패키지 디렉토리로 이동
cd "$OPENCODE_PKG_DIR"

# 의존성 설치
echo "Installing dependencies..."
bun install

# 빌드 실행
echo "Running build script (this may take a while as it builds for multiple targets)..."
# bun run script/build.ts는 packages/opencode/package.json의 "build" 스크립트와 동일
bun run build

# 결과물 복사
echo "Copying binaries to dist..."

# Linux x64
if [ -f "dist/opencode-linux-x64/bin/opencode" ]; then
    cp "dist/opencode-linux-x64/bin/opencode" "$OUTPUT_DIR/opencode-linux-x64"
    echo "Copied Linux x64 binary."
else
    echo "Warning: Linux x64 binary not found in dist/opencode-linux-x64/bin/opencode"
fi

# Windows x64
if [ -f "dist/opencode-windows-x64/bin/opencode.exe" ]; then
    cp "dist/opencode-windows-x64/bin/opencode.exe" "$OUTPUT_DIR/opencode-windows-x64.exe"
    echo "Copied Windows x64 binary."
else
    echo "Warning: Windows x64 binary not found in dist/opencode-windows-x64/bin/opencode"
fi

echo "---------------------------------------------------"
echo "Build complete!"
echo "Binaries are located in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
echo "---------------------------------------------------"
