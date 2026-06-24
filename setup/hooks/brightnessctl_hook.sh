#!/bin/bash

set -euo pipefail

log() {
	echo "setup/hooks/brightnessctl_hook - $*"
}

if id -nG "$USER" | tr ' ' '\n' | grep -Fxq video; then
	log "$USER is already in the video group"
	exit 0
fi

log "Adding $USER to the video group"
sudo usermod -aG video "$USER"
log "Log out and back in for the new group membership to apply"
