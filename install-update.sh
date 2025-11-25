#!/bin/bash

# Wine Cellar Plugin - Build and Install Script
# This script rebuilds the frontend and backend, then deploys to the Decky plugins directory

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="decky-wine-cellar"
PLUGIN_VERSION=$(grep -oP '"version":\s*"\K[^"]+' "${SCRIPT_DIR}/package.json")
HOMEBREW_DIR="${HOME}/homebrew"

# Find the installed plugin directory (may have different version suffix)
if [[ -d "${HOMEBREW_DIR}/plugins" ]]; then
    INSTALLED_DIR=$(find "${HOMEBREW_DIR}/plugins" -maxdepth 1 -type d -name "${PLUGIN_NAME}*" | head -1)
fi

# Use found directory or default to version from package.json
if [[ -n "${INSTALLED_DIR}" ]]; then
    TARGET_DIR="${INSTALLED_DIR}"
else
    TARGET_DIR="${HOMEBREW_DIR}/plugins/${PLUGIN_NAME}-${PLUGIN_VERSION}"
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Wine Cellar Plugin Build & Install${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${BLUE}Version: ${PLUGIN_VERSION}${NC}"
echo -e "${BLUE}Target:  ${TARGET_DIR}${NC}"
echo ""

# Check if we're in the right directory
if [[ ! -f "${SCRIPT_DIR}/package.json" ]]; then
    echo -e "${RED}Error: package.json not found. Run this script from the plugin root directory.${NC}"
    exit 1
fi

# Step 1: Build Frontend
echo -e "${YELLOW}[1/5] Building frontend...${NC}"
cd "${SCRIPT_DIR}"

if [[ ! -d "node_modules" ]]; then
    echo -e "${YELLOW}      Installing npm dependencies...${NC}"
    npm install
fi

npm run build
echo -e "${GREEN}      Frontend build complete!${NC}"

# Step 2: Build Backend
echo -e "${YELLOW}[2/5] Building backend (Wine Cask)...${NC}"
cd "${SCRIPT_DIR}/backend"

# Source cargo environment if needed
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

# Check if cargo is available
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}Error: Rust/Cargo not found. Install Rust first:${NC}"
    echo -e "${RED}  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh${NC}"
    exit 1
fi

cargo build --release
mkdir -p out
cp target/release/wine-cask out/backend
echo -e "${GREEN}      Backend build complete!${NC}"

# Step 3: Stop Decky Loader
echo -e "${YELLOW}[3/5] Stopping Decky Loader...${NC}"
sudo systemctl stop plugin_loader
echo -e "${GREEN}      Decky Loader stopped!${NC}"

# Step 4: Deploy to target directory
echo -e "${YELLOW}[4/5] Deploying to ${TARGET_DIR}...${NC}"

# Check if target directory exists
if [[ ! -d "${TARGET_DIR}" ]]; then
    echo -e "${RED}Error: Target directory does not exist: ${TARGET_DIR}${NC}"
    echo -e "${RED}       Make sure the plugin is installed via Decky first.${NC}"
    sudo systemctl start plugin_loader
    exit 1
fi

# Deploy frontend
echo -e "${YELLOW}      Copying frontend dist...${NC}"
sudo cp -r "${SCRIPT_DIR}/dist/" "${TARGET_DIR}/"

# Deploy backend
echo -e "${YELLOW}      Copying backend binary...${NC}"
sudo mkdir -p "${TARGET_DIR}/bin"
sudo cp "${SCRIPT_DIR}/backend/out/backend" "${TARGET_DIR}/bin/"
sudo chmod +x "${TARGET_DIR}/bin/backend"

echo -e "${GREEN}      Deployment complete!${NC}"

# Step 5: Restart Decky Loader
echo -e "${YELLOW}[5/5] Starting Decky Loader...${NC}"
sudo systemctl start plugin_loader
echo -e "${GREEN}      Decky Loader started!${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Build and Install Successful!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Note: After restarting, go to About tab and click 'Check For Updates'${NC}"
echo -e "${YELLOW}      to populate the remote version lists.${NC}"
