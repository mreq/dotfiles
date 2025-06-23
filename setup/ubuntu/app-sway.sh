#!/bin/bash

set -e

if ! command -v sway &> /dev/null; then
  echo "setup/ubuntu/app-sway - Running apt install sway"
  sudo apt install -y sway
fi

if [ ! -f /usr/share/wayland-sessions/sway-in-bash.desktop ]; then
  echo "setup/ubuntu/app-sway - Creating sway-in-bash.desktop"

  sudo tee /usr/share/wayland-sessions/sway-in-bash.desktop > /dev/null << EOF
[Desktop Entry]
Name=Sway in bash
Comment=An i3-compatible Wayland compositor
Exec=bash --login -c 'ssh-agent sway'
Type=Application
DesktopNames=sway
EOF
fi

echo "setup/ubuntu/app-sway - ✓"
