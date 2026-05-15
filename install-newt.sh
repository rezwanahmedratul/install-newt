#!/bin/sh

# ==============================================================================
# Newt Universal Installer for Pangolin
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

echo "===================================================="
echo "          Newt Installation Script                  "
echo "===================================================="

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

# -------------------------
# Get Credentials (Handles curl | sh stdin issues)
# -------------------------
echo ""
echo "--- Configuration ---"

# Function to read input safely from terminal
prompt_input() {
    prompt_text=$1
    var_name=$2
    eval current_val=\$$var_name
    if [ -z "$current_val" ]; then
        # Read from /dev/tty to allow interaction when piped to sh
        printf "%s" "$prompt_text" > /dev/tty
        read -r input_val < /dev/tty
        eval "$var_name=\$input_val"
    fi
}

prompt_input "Enter Newt ID: " NEWT_ID
prompt_input "Enter Newt Secret: " NEWT_SECRET
prompt_input "Enter Pangolin Endpoint (e.g., https://your-pangolin.com): " PANGOLIN_ENDPOINT

# Validate input
if [ -z "$NEWT_ID" ] || [ -z "$NEWT_SECRET" ] || [ -z "$PANGOLIN_ENDPOINT" ]; then
    echo "Error: ID, Secret, and Endpoint are required."
    exit 1
fi

# -------------------------
# Install dependencies
# -------------------------
echo ""
echo "[1/5] Installing dependencies..."
if command -v apk >/dev/null 2>&1; then
    apk update && apk add curl bash sudo
elif command -v apt-get >/dev/null 2>&1; then
    apt-get update && apt-get install -y curl bash sudo
elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl bash sudo
elif command -v pacman >/dev/null 2>&1; then
    pacman -S --noconfirm curl bash sudo
else
    echo "Unsupported OS/Package Manager."
    exit 1
fi

# -------------------------
# Install Newt
# -------------------------
echo ""
echo "[2/5] Installing Newt..."
curl -fsSL https://static.pangolin.net/get-newt.sh | bash

if ! command -v newt >/dev/null 2>&1; then
    echo "ERROR: Newt installation failed."
    exit 1
fi

# -------------------------
# Create Config
# -------------------------
echo ""
echo "[3/5] Creating config..."
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
echo "Config saved to $CONF_DIR/config.json"

# -------------------------
# Set up Service
# -------------------------
echo ""
echo "[4/5] Setting up service..."

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
    echo "OpenRC service configured and started."

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
    echo "Systemd service configured and started."

else
    echo "No supported init system (Systemd or OpenRC) found."
    exit 1
fi

# -------------------------
# Done
# -------------------------
echo ""
echo "[5/5] Done - Newt installed and running!"
echo "Config: /etc/newt/config.json"
echo "===================================================="
