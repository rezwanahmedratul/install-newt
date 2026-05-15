#!/bin/bash

# ==============================================================================
# Newt Installer for Pangolin
# ==============================================================================
# This script automates the installation of the Newt client, configures
# environment variables, and sets up a systemd service.
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}          Newt Installation Script                  ${NC}"
echo -e "${BLUE}====================================================${NC}"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root (use sudo).${NC}"
  exit 1
fi

# Variables
NEWT_BINARY_URL_BASE="https://github.com/fosrl/newt/releases/latest/download"
INSTALL_DIR="/usr/local/bin"
CONF_DIR="/etc/newt"
ENV_FILE="$CONF_DIR/newt.env"
SERVICE_FILE="/etc/systemd/system/newt.service"

# Detect Architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)  NEWT_ARCH="amd64" ;;
    aarch64) NEWT_ARCH="arm64" ;;
    *)       echo -e "${RED}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

# Get Credentials
echo -e "\n${BLUE}--- Configuration ---${NC}"
if [ -z "$NEWT_ID" ]; then
    read -p "Enter Newt ID: " NEWT_ID
fi
if [ -z "$NEWT_SECRET" ]; then
    read -p "Enter Newt Secret: " NEWT_SECRET
fi
if [ -z "$PANGOLIN_ENDPOINT" ]; then
    read -p "Enter Pangolin Endpoint (e.g., https://your-pangolin.com): " PANGOLIN_ENDPOINT
fi

if [[ -z "$NEWT_ID" || -z "$NEWT_SECRET" || -z "$PANGOLIN_ENDPOINT" ]]; then
    echo -e "${RED}Error: ID, Secret, and Endpoint are required.${NC}"
    exit 1
fi

# Create Config Directory
mkdir -p "$CONF_DIR"
chmod 700 "$CONF_DIR"

# Download Newt
echo -e "\n${BLUE}--- Downloading Newt ($NEWT_ARCH) ---${NC}"
NEWT_URL="${NEWT_BINARY_URL_BASE}/newt-linux-${NEWT_ARCH}"
curl -fsSL "$NEWT_URL" -o "$INSTALL_DIR/newt"
chmod +x "$INSTALL_DIR/newt"
echo -e "${GREEN}Newt binary installed to $INSTALL_DIR/newt${NC}"

# Create Environment File
echo -e "\n${BLUE}--- Configuring Environment ---${NC}"
cat <<EOF > "$ENV_FILE"
NEWT_ID=$NEWT_ID
NEWT_SECRET=$NEWT_SECRET
PANGOLIN_ENDPOINT=$PANGOLIN_ENDPOINT
EOF
chmod 600 "$ENV_FILE"
echo -e "${GREEN}Environment configuration saved to $ENV_FILE${NC}"

# Create Systemd Service
echo -e "\n${BLUE}--- Setting up Systemd Service ---${NC}"
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Newt - Pangolin Tunnel Client
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=$ENV_FILE
ExecStart=$INSTALL_DIR/newt
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Reload and Start
systemctl daemon-reload
systemctl enable newt
systemctl restart newt

echo -e "\n${BLUE}--- Installation Complete ---${NC}"
echo -e "${GREEN}Newt has been installed and started.${NC}"
echo -e "Check status with: ${BLUE}systemctl status newt${NC}"
echo -e "View logs with:   ${BLUE}journalctl -u newt -f${NC}"
echo -e "${BLUE}====================================================${NC}"
