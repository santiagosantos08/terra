#!/bin/bash
set -e

# Customize your install, provide a different map.
INSTALL_DIR="$HOME/terra"
CACHE_DIR="$HOME/.cache/terra"
SERVICE_FILE="$HOME/.config/systemd/user/terra.service"
MAP_URL="https://shadedrelief.com/natural3/ne3_data/16200/textures/1_earth_16k.jpg"

echo "--- INSTALLING TERRA ---"

mkdir -p "$INSTALL_DIR"

if [ -f "terra.sh" ]; then
    echo "[INFO] Copying scripts to $INSTALL_DIR..."
    cp terra.sh "$INSTALL_DIR/"
    if [ -f "settings.yaml" ]; then
        cp settings.yaml "$INSTALL_DIR/"
    fi
    chmod +x "$INSTALL_DIR/terra.sh"
else
    echo "[WARN] terra.sh not found in current directory."
    echo "       Assuming it is already in $INSTALL_DIR."
fi

echo "[INFO] Setting up cache and downloading map..."
mkdir -p "$CACHE_DIR"
curl -L -A "Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" -o "$CACHE_DIR/earth_map.jpg" "$MAP_URL"

# Systemd service
echo "[INFO] Creating systemd service..."
mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Terra Live Globe Wallpaper
After=graphical-session.target network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/terra.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=graphical-session.target
EOF

echo "[INFO] Enabling and starting service..."
systemctl --user daemon-reload
systemctl --user enable --now terra.service

echo "--- INSTALLATION COMPLETE ---"
echo "Terra is running. You can check status with: systemctl --user status terra"