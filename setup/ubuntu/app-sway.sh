#!/bin/bash

set -e

DESKTOP_FILE=/usr/share/wayland-sessions/sway-in-bash.desktop

if ! command -v sway &>/dev/null; then
	echo "setup/ubuntu/app-sway - Running apt install sway"
	sudo apt install -y sway
fi

if [[ ! -f "$DESKTOP_FILE" ]] || ! grep -Fq "sway_session" "$DESKTOP_FILE"; then
	echo "setup/ubuntu/app-sway - Creating sway-in-bash.desktop"

	sudo tee "$DESKTOP_FILE" >/dev/null <<'EOF'
[Desktop Entry]
Name=Sway in bash
Comment=An i3-compatible Wayland compositor
Exec=bash --login -c 'exec "$HOME/.local/share/dotfiles/bin/sway/sway_session"'
Type=Application
DesktopNames=sway
EOF
fi

echo "setup/ubuntu/app-sway - ✓"
