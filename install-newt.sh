#!/bin/bash

# ==============================================================================
# Newt Installer for Pangolin
# ==============================================================================
# This script automates the installation of the Newt client, configures
# credentials, and sets up a system service (systemd or OpenRC).
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

# -------------------------
# Get Credentials (Handles curl | bash stdin issues)
# -------------------------
echo -e "\n${BLUE}--- Configuration ---${NC}"

# Function to read input safely from terminal
prompt_input() {
    local prompt_text=$1
    local var_name=$2
    if [ -z "${!var_name}" ]; then
        # Read from /dev/tty to allow interaction when piped to bash
        echo -n "$prompt_text" > /dev/tty
        read -r "$var_name" < /dev/tty
    fi
}

prompt_input "Enter Newt ID: " NEWT_ID
prompt_input "Enter Newt Secret: " NEWT_SECRET
prompt_input "Enter Pangolin Endpoint (e.g., https://your-pangolin.com): " PANGOLIN_ENDPOINT

# Validate input
if [[ -z "$NEWT_ID" || -z "$NEWT_SECRET" || -z "$PANGOLIN_ENDPOINT" ]]; then
    echo -e "${RED}Error: ID, Secret, and Endpoint are required.${NC}"
    exit 1
fi

# -------------------------
# Install dependencies
# -------------------------
echo -e "\n${BLUE}[1/5] Installing dependencies...${NC}"
if command -v apt-get >/dev/null 2>&1; then
    apt-get update && apt-get install -y curl bash sudo
elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl bash sudo
elif command -v pacman >/dev/null 2>&1; then
    pacman -S --noconfirm curl bash sudo
else
    echo -e "${RED}Unsupported OS/Package Manager.${NC}"
    exit 1
fi

# -------------------------
# Install Newt
# -------------------------
echo -e "\n${BLUE}[2/5] Installing Newt...${NC}"
curl -fsSL https://static.pangolin.net/get-newt.sh | bash

if ! command -v newt >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Newt installation failed.${NC}"
    exit 1
fi

# -------------------------
# Create Config
# -------------------------
echo -e "\n${BLUE}[3/5] Creating config...${NC}"
CONF_DIR="/etc/newt"
mkdir -p "$CONF_DIR"
chmod 700 "$CONF_DIR"

cat <<EOF > "$CONF_DIR/config.json"
{
  "id": "$NEWT_ID",
  "secret": "$NEWT_SECRET",
  "endpoint": "$PANGOLIN_ENDPOINT"
}
EOF
chmod 600 "$CONF_DIR/config.json"
echo -e "${GREEN}Config saved to $CONF_DIR/config.json${NC}"

# -------------------------
# Set up Service
# -------------------------
echo -e "\n${BLUE}[4/5] Setting up service...${NC}"

if [ -f /sbin/openrc ] || command -v rc-service >/dev/null 2>&1; then
    # OpenRC (Alpine, etc.)
    cat << 'EOF' > /etc/init.d/newt
#!/sbin/openrc-run
description="Newt - Pangolin Tunnel Client"
command="/usr/local/bin/newt"
command_args="-c /etc/newt/config.json"
pidfile="/run/newt.pid"
command_background="yes"

depend() {
    need net
    after firewall
}
EOF
    chmod +x /etc/init.d/newt
    rc-update add newt default >/dev/null 2>&1 || true
    rc-service newt restart || rc-service newt start
    echo -e "${GREEN}OpenRC service configured and started.${NC}"

elif command -v systemctl >/dev/null 2>&1; then
    # Systemd
    cat <<EOF > /etc/systemd/system/newt.service
[Unit]
Description=Newt - Pangolin Tunnel Client
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/newt -c /etc/newt/config.json
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable newt
    systemctl restart newt
    echo -e "${GREEN}Systemd service configured and started.${NC}"

else
    echo -e "${RED}No supported init system (Systemd or OpenRC) found.${NC}"
    exit 1
fi

# -------------------------
# Done
# -------------------------
echo -e "\n${BLUE}[5/5] Done - Newt installed and running!${NC}"
echo -e "Config: ${BLUE}/etc/newt/config.json${NC}"
echo -e "${BLUE}====================================================${NC}"
