#!/bin/bash

set -euo pipefail

ROOTLESS_BIN="$HOME/.local/share/docker-rootless/bin"
DOCKER_CONTRIB_DIR=/usr/share/docker.io/contrib
DOCKER_HOST_SOCKET="unix:///run/user/$(id -u)/docker.sock"

log() {
	echo "setup/hooks/docker_rootless_hook - $*"
}

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		log "ERROR: missing required command: $1"
		exit 1
	fi
}

disable_system_units() {
	local existing=()
	local unit

	if ! command -v systemctl >/dev/null 2>&1; then
		return
	fi

	for unit in "$@"; do
		if systemctl is-enabled --quiet "$unit" || systemctl is-active --quiet "$unit"; then
			existing+=("$unit")
		fi
	done

	if ((${#existing[@]} == 0)); then
		return
	fi

	log "Disabling system services: ${existing[*]}"
	sudo systemctl disable --now "${existing[@]}" >/dev/null 2>&1 || true
}

disable_rootful_docker() {
	disable_system_units docker.service docker.socket containerd.service ubuntu-fan.service
}

ensure_subid_entry() {
	local file=$1
	local flag=$2
	local user=$3
	local uid

	uid=$(id -u)

	if grep -Eq "^(${user}|${uid}):" "$file" 2>/dev/null; then
		return
	fi

	log "Adding ${file##*/} entry for $user"
	sudo usermod "$flag" 100000-165535 "$user"
}

ensure_rootless_bin_dir() {
	local rootlesskit_bin

	if [[ ! -x "$DOCKER_CONTRIB_DIR/dockerd-rootless-setuptool.sh" ]]; then
		log "ERROR: $DOCKER_CONTRIB_DIR/dockerd-rootless-setuptool.sh not found"
		exit 1
	fi

	if [[ ! -x "$DOCKER_CONTRIB_DIR/dockerd-rootless.sh" ]]; then
		log "ERROR: $DOCKER_CONTRIB_DIR/dockerd-rootless.sh not found"
		exit 1
	fi

	rootlesskit_bin=$(command -v rootlesskit || true)
	if [[ -z "$rootlesskit_bin" ]]; then
		log "ERROR: rootlesskit not found"
		exit 1
	fi

	install -d -m 0755 "$ROOTLESS_BIN"
	ln -sf /usr/bin/docker "$ROOTLESS_BIN/docker"
	ln -sf "$DOCKER_CONTRIB_DIR/dockerd-rootless.sh" "$ROOTLESS_BIN/dockerd-rootless.sh"
	ln -sf "$DOCKER_CONTRIB_DIR/dockerd-rootless-setuptool.sh" "$ROOTLESS_BIN/dockerd-rootless-setuptool.sh"
	ln -sf "$rootlesskit_bin" "$ROOTLESS_BIN/rootlesskit"
}

install_rootless_docker() {
	if [[ -f "$HOME/.config/systemd/user/docker.service" ]]; then
		log "Rootless Docker user service already installed"
		return
	fi

	log "Installing rootless Docker user service"
	PATH="$ROOTLESS_BIN:$PATH" "$ROOTLESS_BIN/dockerd-rootless-setuptool.sh" install
}

enable_rootless_service() {
	if ! systemctl --user show-environment >/dev/null 2>&1; then
		log "User systemd is not available; rootless Docker may need manual start"
		return
	fi

	log "Enabling rootless Docker user service"
	systemctl --user daemon-reload
	systemctl --user enable --now docker.service
}

use_rootless_context() {
	if env -u DOCKER_HOST docker context inspect rootless >/dev/null 2>&1; then
		env -u DOCKER_HOST docker context use rootless >/dev/null
	fi
}

warn_docker_group() {
	if id -nG | tr ' ' '\n' | grep -qx docker; then
		log "WARN: user is in the docker group; remove that membership to avoid rootful Docker access"
	fi
}

verify_rootless_docker() {
	if DOCKER_HOST="$DOCKER_HOST_SOCKET" docker info 2>/dev/null | grep -q "rootless"; then
		log "Rootless Docker is running"
		return
	fi

	log "WARN: rootless Docker is configured but not responding yet; try logging out and back in"
}

require_command docker
require_command sudo
require_command usermod

disable_rootful_docker
ensure_subid_entry /etc/subuid --add-subuids "$(id -un)"
ensure_subid_entry /etc/subgid --add-subgids "$(id -un)"
ensure_rootless_bin_dir
install_rootless_docker
enable_rootless_service
use_rootless_context
warn_docker_group
verify_rootless_docker
