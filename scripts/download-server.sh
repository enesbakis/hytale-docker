#!/bin/bash
#
# Hytale Server Files Downloader
# Downloads server files using the official Hytale Downloader CLI
#
# Usage: ./download-server.sh [output-directory]
#
# Requirements:
#   - curl, unzip
#   - Browser access for OAuth2 authentication
#
# Note: This script must be run on the host machine, not inside Docker.
#       The CLI requires browser-based OAuth2 authentication.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[Downloader]${NC} $1"; }
warn() { echo -e "${YELLOW}[Downloader]${NC} $1"; }
error() { echo -e "${RED}[Downloader]${NC} $1"; }
info() { echo -e "${BLUE}[Downloader]${NC} $1"; }

# Configuration
DOWNLOADER_URL="https://downloader.hytale.com/hytale-downloader.zip"
TEMP_DIR=$(mktemp -d)
OUTPUT_DIR="${1:-./data}"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Detect platform
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case "$os" in
        linux*)
            case "$arch" in
                x86_64|amd64) echo "linux-amd64" ;;
                aarch64|arm64) echo "linux-arm64" ;;
                *) echo "unsupported" ;;
            esac
            ;;
        mingw*|msys*|cygwin*)
            echo "windows-amd64"
            ;;
        darwin*)
            error "macOS is not supported by Hytale Downloader CLI."
            error "Please copy server files manually from your Hytale Launcher installation:"
            error "  ~/Application Support/Hytale/install/release/package/game/latest"
            exit 1
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

# Check dependencies
check_dependencies() {
    local missing=()
    
    for cmd in curl unzip; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required dependencies: ${missing[*]}"
        error "Please install them and try again."
        exit 1
    fi
}

# Download and extract the CLI tool
download_cli() {
    log "Downloading Hytale Downloader CLI..."
    curl -fsSL "$DOWNLOADER_URL" -o "$TEMP_DIR/hytale-downloader.zip"
    
    log "Extracting CLI tool..."
    unzip -q "$TEMP_DIR/hytale-downloader.zip" -d "$TEMP_DIR/cli"
}

# Find the correct executable
find_executable() {
    local platform="$1"
    local exe_name="hytale-downloader"
    
    if [[ "$platform" == windows* ]]; then
        exe_name="hytale-downloader.exe"
    fi
    
    # Find the executable in extracted files
    local exe_path=$(find "$TEMP_DIR/cli" -name "$exe_name" -type f 2>/dev/null | head -n 1)
    
    if [ -z "$exe_path" ]; then
        error "Could not find hytale-downloader executable"
        exit 1
    fi
    
    echo "$exe_path"
}

# Download server files
download_server_files() {
    local exe_path="$1"
    local game_zip="$TEMP_DIR/game.zip"
    
    # Make executable
    chmod +x "$exe_path"
    
    log "Starting download..."
    info "A browser window will open for authentication."
    info "Please log in with your Hytale account."
    echo ""
    
    # Run the downloader
    "$exe_path" -download-path "$game_zip"
    
    if [ ! -f "$game_zip" ]; then
        error "Download failed - game.zip not found"
        exit 1
    fi
    
    log "Download complete!"
    echo "$game_zip"
}

# Extract and organize files
extract_files() {
    local game_zip="$1"
    local extract_dir="$TEMP_DIR/game"
    
    log "Extracting game files..."
    mkdir -p "$extract_dir"
    unzip -q "$game_zip" -d "$extract_dir"
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Find and copy Server folder contents
    local server_dir=$(find "$extract_dir" -type d -name "Server" 2>/dev/null | head -n 1)
    if [ -n "$server_dir" ] && [ -d "$server_dir" ]; then
        log "Copying server files..."
        cp -r "$server_dir"/* "$OUTPUT_DIR/"
    else
        warn "Server folder not found, copying all files..."
        cp -r "$extract_dir"/* "$OUTPUT_DIR/"
    fi
    
    # Find and copy Assets.zip
    local assets_file=$(find "$extract_dir" -name "Assets.zip" -type f 2>/dev/null | head -n 1)
    if [ -n "$assets_file" ]; then
        log "Copying Assets.zip..."
        cp "$assets_file" "$OUTPUT_DIR/"
    else
        warn "Assets.zip not found in downloaded files"
    fi
}

# Verify installation
verify_files() {
    local required_files=("HytaleServer.jar" "Assets.zip")
    local missing=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$OUTPUT_DIR/$file" ]; then
            missing+=("$file")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        warn "Missing files: ${missing[*]}"
        warn "The download may be incomplete."
        return 1
    fi
    
    return 0
}

# Main
main() {
    echo ""
    echo "======================================"
    echo "  Hytale Server Files Downloader"
    echo "======================================"
    echo ""
    
    # Check platform
    local platform=$(detect_platform)
    if [ "$platform" = "unsupported" ]; then
        error "Unsupported platform: $(uname -s) $(uname -m)"
        error "Hytale Downloader CLI supports Linux (x64/arm64) and Windows only."
        exit 1
    fi
    
    info "Platform: $platform"
    info "Output directory: $OUTPUT_DIR"
    echo ""
    
    # Check for existing files
    if [ -f "$OUTPUT_DIR/HytaleServer.jar" ]; then
        warn "Server files already exist in $OUTPUT_DIR"
        read -p "Overwrite existing files? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Cancelled."
            exit 0
        fi
    fi
    
    # Run steps
    check_dependencies
    download_cli
    
    local exe_path=$(find_executable "$platform")
    info "Using: $exe_path"
    
    local game_zip=$(download_server_files "$exe_path")
    extract_files "$game_zip"
    
    echo ""
    if verify_files; then
        log "Server files downloaded successfully!"
        log "Files are located in: $OUTPUT_DIR"
        echo ""
        info "Next steps:"
        info "  1. Run: docker compose up -d"
        info "  2. Authenticate: docker compose logs -f"
    else
        warn "Some files may be missing. Please verify manually."
    fi
    echo ""
}

main "$@"
