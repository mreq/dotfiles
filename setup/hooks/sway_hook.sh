#!/bin/bash

set -euo pipefail

DESKTOP_FILE=/usr/share/wayland-sessions/sway-in-bash.desktop
DOTFILES_DIR=${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}

log() {
	echo "setup/hooks/sway_hook - $*"
}

if [[ -f "$DESKTOP_FILE" ]] && grep -Fq "sway_session" "$DESKTOP_FILE"; then
	log "$DESKTOP_FILE already points to sway_session"
	exit 0
fi

tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT

cat >"$tmp_file" <<EOF
[Desktop Entry]
Name=Sway in bash
Comment=An i3-compatible Wayland compositor
Exec=bash --login -c 'exec "\$HOME/.local/share/dotfiles/bin/sway/sway_session"'
Type=Application
DesktopNames=sway
EOF

log "Creating $DESKTOP_FILE"
sudo install -D -m 0644 "$tmp_file" "$DESKTOP_FILE"
