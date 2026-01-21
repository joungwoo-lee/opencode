
import { $ } from "bun"
import path from "path"
import fs from "fs/promises"

// Configuration
const ASSETS_DIR = path.join(process.cwd(), "dist", "offline", "assets")
const BIN_DIR = path.join(process.cwd(), "dist", "offline", "bin")
const DIST_DIR = path.join(process.cwd(), "dist", "offline")

await $`mkdir -p ${ASSETS_DIR}`
await $`mkdir -p ${BIN_DIR}`

console.log("📦 Starting offline bundle creation...")

// 1. Download WASM Parsers
console.log("⬇️  Downloading Tree-sitter WASM parsers...")
const parsers = [
    "https://github.com/tree-sitter/tree-sitter-python/releases/download/v0.23.6/tree-sitter-python.wasm",
    "https://github.com/tree-sitter/tree-sitter-rust/releases/download/v0.24.0/tree-sitter-rust.wasm",
    "https://github.com/tree-sitter/tree-sitter-go/releases/download/v0.25.0/tree-sitter-go.wasm",
    "https://github.com/tree-sitter/tree-sitter-cpp/releases/download/v0.23.4/tree-sitter-cpp.wasm",
    "https://github.com/tree-sitter/tree-sitter-c-sharp/releases/download/v0.23.1/tree-sitter-c_sharp.wasm",
    "https://github.com/tree-sitter/tree-sitter-bash/releases/download/v0.25.0/tree-sitter-bash.wasm",
    "https://github.com/tree-sitter/tree-sitter-c/releases/download/v0.24.1/tree-sitter-c.wasm",
    "https://github.com/tree-sitter/tree-sitter-java/releases/download/v0.23.5/tree-sitter-java.wasm",
    "https://github.com/tree-sitter/tree-sitter-ruby/releases/download/v0.23.1/tree-sitter-ruby.wasm",
    "https://github.com/tree-sitter/tree-sitter-php/releases/download/v0.24.2/tree-sitter-php.wasm",
    "https://github.com/tree-sitter/tree-sitter-scala/releases/download/v0.24.0/tree-sitter-scala.wasm",
    "https://github.com/tree-sitter/tree-sitter-html/releases/download/v0.23.2/tree-sitter-html.wasm",
    "https://github.com/tree-sitter/tree-sitter-json/releases/download/v0.24.8/tree-sitter-json.wasm",
    "https://github.com/tree-sitter-grammars/tree-sitter-yaml/releases/download/v0.7.2/tree-sitter-yaml.wasm",
    "https://github.com/tree-sitter/tree-sitter-haskell/releases/download/v0.23.1/tree-sitter-haskell.wasm",
    "https://github.com/tree-sitter/tree-sitter-css/releases/download/v0.25.0/tree-sitter-css.wasm",
    "https://github.com/tree-sitter/tree-sitter-julia/releases/download/v0.23.1/tree-sitter-julia.wasm",
    "https://github.com/tree-sitter/tree-sitter-ocaml/releases/download/v0.24.2/tree-sitter-ocaml.wasm",
    "https://github.com/sogaiu/tree-sitter-clojure/releases/download/v0.0.13/tree-sitter-clojure.wasm",
    "https://github.com/alex-pinkus/tree-sitter-swift/releases/download/0.7.1/tree-sitter-swift.wasm",
    "https://github.com/ast-grep/ast-grep.github.io/raw/40b84530640aa83a0d34a20a2b0623d7b8e5ea97/website/public/parsers/tree-sitter-nix.wasm"
]

const parserDir = path.join(ASSETS_DIR, "parsers")
await $`mkdir -p ${parserDir}`

for (const url of parsers) {
    const filename = path.basename(url)
    const dest = path.join(parserDir, filename)
    if (await fs.exists(dest)) {
        console.log(`  Skipping ${filename} (already exists)`)
        continue
    }
    console.log(`  Downloading ${filename}...`)
    try {
        await $`curl -L -o ${dest} ${url}`
    } catch (e) {
        console.error(`  Failed to download ${url}`)
    }
}

// 2. Download Ripgrep
console.log("⬇️  Downloading Ripgrep...")
// Assuming Linux x64 for now as per previous context, or we can make it generic
const rgVersion = "14.1.1"
const rgPlatform = "x86_64-unknown-linux-musl" 
const rgFilename = `ripgrep-${rgVersion}-${rgPlatform}.tar.gz`
const rgUrl = `https://github.com/BurntSushi/ripgrep/releases/download/${rgVersion}/${rgFilename}`
const rgDest = path.join(ASSETS_DIR, rgFilename)

if (!(await fs.exists(rgDest))) {
    console.log(`  Downloading ${rgFilename}...`)
    await $`curl -L -o ${rgDest} ${rgUrl}`
}

// 3. Download LSPs (Static URLs)
console.log("⬇️  Downloading Static LSPs...")
const staticLsps = [
    { name: "vscode-eslint.zip", url: "https://github.com/microsoft/vscode-eslint/archive/refs/heads/main.zip" },
    { name: "elixir-ls.zip", url: "https://github.com/elixir-lsp/elixir-ls/archive/refs/heads/master.zip" },
    { name: "jdtls-latest.tar.gz", url: "https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz" }
]

for (const lsp of staticLsps) {
    const dest = path.join(ASSETS_DIR, lsp.name)
    if (await fs.exists(dest)) continue
    console.log(`  Downloading ${lsp.name}...`)
    await $`curl -L -o ${dest} '${lsp.url}'`
}

// 4. Download Dynamic LSPs (GitHub Releases)
// Note: This is simplified. In a real scenario, we might want to check the platform of the target machine.
// Here we assume Linux x64 for the target.
console.log("⬇️  Downloading Dynamic LSPs (Linux x64)...")

async function downloadLatestGithubRelease(repo: string, assetPattern: RegExp, outputName?: string) {
    try {
        const releaseUrl = `https://api.github.com/repos/${repo}/releases/latest`
        const release = await fetch(releaseUrl).then(r => r.json())
        const asset = release.assets.find((a: any) => assetPattern.test(a.name))
        
        if (!asset) {
            console.error(`  No asset matching ${assetPattern} found for ${repo}`)
            return
        }

        const name = outputName || asset.name
        const dest = path.join(ASSETS_DIR, name)
        if (await fs.exists(dest)) return

        console.log(`  Downloading ${name} from ${repo}...`)
        await $`curl -L -o ${dest} ${asset.browser_download_url}`
    } catch (e) {
        console.error(`  Failed to download from ${repo}: ${e}`)
    }
}

// zls
await downloadLatestGithubRelease("zigtools/zls", /zls-x86_64-linux\.tar\.xz/)
// clangd
await downloadLatestGithubRelease("clangd/clangd", /clangd-linux-.*\.zip/)
// lua-language-server
await downloadLatestGithubRelease("LuaLS/lua-language-server", /linux-x64\.tar\.gz/)
// terraform-ls
await downloadLatestGithubRelease("hashicorp/terraform-ls", /linux_amd64\.zip/)
// texlab
await downloadLatestGithubRelease("latex-lsp/texlab", /x86_64-linux\.tar\.gz/)
// tinymist
await downloadLatestGithubRelease("Myriad-Dreamin/tinymist", /x86_64-unknown-linux-gnu\.tar\.gz/)
// kotlin-lsp
await downloadLatestGithubRelease("Kotlin/kotlin-lsp", /linux-x64\.zip/)

// 5. Build Binary
console.log("🔨 Building Opencode Binary...")
const OPENCODE_DIR = path.join(process.cwd(), "packages", "opencode")
// Change directory to packages/opencode to run the build script
await $`bun run script/build.ts --single`.cwd(OPENCODE_DIR)

// Find binary
const distDir = path.join(OPENCODE_DIR, "dist")
const builtBinDir = (await fs.readdir(distDir)).find(d => d.startsWith("opencode-linux-x64"))
if (builtBinDir) {
    const binPath = path.join(distDir, builtBinDir, "bin", "opencode")
    await $`cp ${binPath} ${BIN_DIR}/opencode`
    console.log(`  Copied binary to ${BIN_DIR}/opencode`)
} else {
    console.error("  Could not find built binary")
}

// 6. Create Install Script
const installScript = `#!/bin/bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/share/opencode"
BIN_DIR="$HOME/.opencode/bin"

echo "Installing Opencode Offline Bundle..."

# 1. Install Binary
mkdir -p "$BIN_DIR"
cp bin/opencode "$BIN_DIR/opencode"
chmod +x "$BIN_DIR/opencode"
echo "Installed binary to $BIN_DIR/opencode"

# 2. Install Assets
mkdir -p "$INSTALL_DIR/bin"
echo "Installing assets to $INSTALL_DIR/bin..."

# Copy parsers
mkdir -p "$INSTALL_DIR/bin/parsers"
cp -r assets/parsers/* "$INSTALL_DIR/bin/parsers/"

# Copy Ripgrep
# Opencode expects the binary 'rg' (or rg.exe) to exist in bin/
# or it will try to download.
# We should extract it.
echo "Extracting Ripgrep..."
for f in assets/ripgrep*.tar.gz; do
    [ -e "$f" ] || continue
    # extract to temp
    tar -xzf "$f" -C "$INSTALL_DIR/bin"
    # move binary to top level bin if nested
    find "$INSTALL_DIR/bin" -name "rg" -type f -exec mv {} "$INSTALL_DIR/bin/rg" \;
    # clean up dir
    find "$INSTALL_DIR/bin" -type d -name "ripgrep*" -exec rm -rf {} +
done

# Extract LSPs
echo "Extracting LSPs..."
for f in assets/*.tar.gz; do
    [ -e "$f" ] || continue
    [[ "$f" == *"ripgrep"* ]] && continue # skip ripgrep
    tar -xzf "$f" -C "$INSTALL_DIR/bin"
done

for f in assets/*.tar.xz; do
    [ -e "$f" ] || continue
    tar -xf "$f" -C "$INSTALL_DIR/bin"
done

for f in assets/*.zip; do
    [ -e "$f" ] || continue
    unzip -q -o "$f" -d "$INSTALL_DIR/bin"
done

# Fix permissions
chmod +x "$INSTALL_DIR/bin/"* 2>/dev/null || true

# Specific fix for some LSPs that might extract into subfolders or need renaming
# (User might need to adjust this based on specific LSP contents)

# 3. Setup Environment
# We need to tell Opencode to look for local parsers.
# This requires setting OPENCODE_OFFLINE_MODE=true in the shell profile.

SHELL_NAME=$(basename "$SHELL")
RC_FILE=""

case "$SHELL_NAME" in
    bash) RC_FILE="$HOME/.bashrc" ;;
    zsh) RC_FILE="$HOME/.zshrc" ;;
    fish) RC_FILE="$HOME/.config/fish/config.fish" ;;
    *) RC_FILE="$HOME/.profile" ;;
esac

if [ -f "$RC_FILE" ]; then
    if ! grep -q "OPENCODE_OFFLINE_MODE" "$RC_FILE"; then
        echo "export OPENCODE_OFFLINE_MODE=true" >> "$RC_FILE"
        echo "Added OPENCODE_OFFLINE_MODE to $RC_FILE"
    fi
    if ! grep -q "$BIN_DIR" "$RC_FILE"; then
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$RC_FILE"
        echo "Added $BIN_DIR to PATH in $RC_FILE"
    fi
fi

echo "✅ Installation Complete!"
echo "Please restart your shell or run: source $RC_FILE"
`

await fs.writeFile(path.join(DIST_DIR, "install.sh"), installScript)
await $`chmod +x ${path.join(DIST_DIR, "install.sh")}`

console.log("✅ Offline bundle created at dist/offline")
console.log("   Zip this folder and transfer to air-gapped machine.")

