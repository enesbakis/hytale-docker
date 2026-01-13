#!/bin/bash
set -e

# Hytale Server Files Download Script
# Downloads server files using Hytale Downloader CLI

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOWNLOAD_DIR="${1:-./server-files}"
DOWNLOADER_URL="https://downloader.hytale.com/hytale-downloader.zip"

log() {
    echo -e "${GREEN}[Download]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[Download]${NC} $1"
}

error() {
    echo -e "${RED}[Download]${NC} $1"
}

# Check for required tools
check_requirements() {
    local missing=0
    
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed"
        missing=1
    fi
    
    if ! command -v unzip &> /dev/null; then
        error "unzip is required but not installed"
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        exit 1
    fi
}

# Detect OS and architecture
detect_platform() {
    case "$(uname -s)" in
        Linux*)  PLATFORM="linux";;
        Darwin*) PLATFORM="macos";;
        MINGW*|MSYS*|CYGWIN*) PLATFORM="windows";;
        *)       PLATFORM="unknown";;
    esac
    
    case "$(uname -m)" in
        x86_64|amd64) ARCH="x64";;
        aarch64|arm64) ARCH="arm64";;
        *)            ARCH="unknown";;
    esac
    
    log "Platform: $PLATFORM ($ARCH)"
}

# Download and extract Hytale Downloader
get_downloader() {
    local temp_dir=$(mktemp -d)
    local downloader_zip="$temp_dir/hytale-downloader.zip"
    
    log "Downloading Hytale Downloader..."
    curl -L -o "$downloader_zip" "$DOWNLOADER_URL"
    
    log "Extracting downloader..."
    unzip -q "$downloader_zip" -d "$temp_dir"
    
    # Find the correct binary
    if [ "$PLATFORM" = "windows" ]; then
        DOWNLOADER_BIN="$temp_dir/hytale-downloader.exe"
    else
        DOWNLOADER_BIN="$temp_dir/hytale-downloader"
        chmod +x "$DOWNLOADER_BIN"
    fi
    
    if [ ! -f "$DOWNLOADER_BIN" ]; then
        error "Could not find downloader binary"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    echo "$temp_dir"
}

# Download server files
download_server() {
    local temp_dir="$1"
    
    mkdir -p "$DOWNLOAD_DIR"
    
    log "Starting download..."
    log "This will open a browser for authentication."
    log ""
    
    cd "$temp_dir"
    
    if [ "$PLATFORM" = "windows" ]; then
        ./hytale-downloader.exe -download-path game.zip
    else
        ./hytale-downloader -download-path game.zip
    fi
    
    if [ ! -f "game.zip" ]; then
        error "Download failed"
        exit 1
    fi
    
    log "Extracting server files..."
    unzip -q game.zip -d extracted
    
    # Copy required files
    if [ -d "extracted/Server" ]; then
        cp -r extracted/Server/* "$DOWNLOAD_DIR/"
        log "Server files copied to $DOWNLOAD_DIR/"
    fi
    
    if [ -f "extracted/Assets.zip" ]; then
        cp extracted/Assets.zip "$DOWNLOAD_DIR/"
        log "Assets.zip copied to $DOWNLOAD_DIR/"
    fi
}

# Cleanup
cleanup() {
    local temp_dir="$1"
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
}

# Main
main() {
    log "Hytale Server Files Download Script"
    log ""
    
    check_requirements
    detect_platform
    
    if [ "$PLATFORM" = "unknown" ] || [ "$ARCH" = "unknown" ]; then
        error "Unsupported platform"
        exit 1
    fi
    
    temp_dir=$(get_downloader)
    
    trap "cleanup '$temp_dir'" EXIT
    
    download_server "$temp_dir"
    
    log ""
    log "Download complete!"
    log "Server files are in: $DOWNLOAD_DIR"
    log ""
    log "Next steps:"
    log "  1. Copy files to your Docker data directory"
    log "  2. Run: docker compose up -d"
}

main "$@"
