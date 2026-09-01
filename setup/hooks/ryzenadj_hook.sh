#!/bin/bash

set -euo pipefail

DOTFILES_DIR=${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
SOURCE_DIR="$DOTFILES_DIR/config/ryzenadj"

RYZENADJ_VERSION=v0.19.0
RYZENADJ_SOURCE_SHA256=d1998b6c2d1b564f5d43c786cbf764ca9a1d8bb213e2001f98f611ead3087c7e
RYZENADJ_SOURCE_URL="https://github.com/FlyGoat/RyzenAdj/archive/refs/tags/$RYZENADJ_VERSION.tar.gz"

RYZENADJ_BINARY=/usr/local/bin/ryzenadj
CONTROLLER_BINARY=/usr/local/bin/thinkpad-thermal
INSTALL_MARKER=/usr/local/share/dotfiles/ryzenadj-install

APPLY_UNIT=/etc/systemd/system/ryzenadj-power-saving.service
CHECK_UNIT=/etc/systemd/system/thinkpad-thermal-check.service
CHECK_TIMER=/etc/systemd/system/thinkpad-thermal-check.timer
SUDOERS_FILE=/etc/sudoers.d/dotfiles-thinkpad-thermal

MANAGED_HEADER="# Managed by dotfiles: setup/hooks/ryzenadj_hook.sh"

log() {
	echo "setup/hooks/ryzenadj_hook - $*"
}

error() {
	log "ERROR: $*" >&2
	exit 1
}

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		error "Missing required command: $1"
	fi
}

require_source() {
	if [[ ! -f "$1" ]]; then
		error "Missing source file: $1"
	fi
}

require_managed_or_absent() {
	local target=$1

	if ! sudo test -e "$target"; then
		return
	fi

	if ! sudo grep -Fxq "$MANAGED_HEADER" "$target"; then
		error "Refusing to overwrite unmanaged file: $target"
	fi
}

install_if_changed() {
	local source=$1
	local target=$2
	local mode=$3

	require_managed_or_absent "$target"

	if sudo test -f "$target" && sudo cmp -s "$source" "$target"; then
		return 1
	fi

	log "Installing $target"
	sudo install -D -m "$mode" "$source" "$target"
	return 0
}

marker_value() {
	local name=$1

	sudo awk -F "=" -v expected_name="$name" '
		$1 == expected_name {
			print $2
			exit
		}
	' "$INSTALL_MARKER"
}

validate_managed_binary() {
	local current_sha256
	local marker_sha256

	if sudo test -L "$RYZENADJ_BINARY" || ! sudo test -f "$RYZENADJ_BINARY"; then
		error "Refusing to replace non-regular file: $RYZENADJ_BINARY"
	fi

	if ! sudo test -f "$INSTALL_MARKER" ||
		! sudo grep -Fxq "$MANAGED_HEADER" "$INSTALL_MARKER"; then
		error "Refusing to replace unmanaged binary: $RYZENADJ_BINARY"
	fi

	marker_sha256=$(marker_value binary_sha256)
	current_sha256=$(sudo sha256sum "$RYZENADJ_BINARY" | awk '{ print $1 }')

	if [[ -z "$marker_sha256" || "$marker_sha256" != "$current_sha256" ]]; then
		error "$RYZENADJ_BINARY differs from its managed install marker"
	fi
}

ryzenadj_install_is_current() {
	local marker_source_sha256
	local marker_version

	if ! sudo test -e "$RYZENADJ_BINARY"; then
		return 1
	fi

	validate_managed_binary

	marker_version=$(marker_value version)
	marker_source_sha256=$(marker_value source_sha256)

	[[ "$marker_version" == "$RYZENADJ_VERSION" ]] &&
		[[ "$marker_source_sha256" == "$RYZENADJ_SOURCE_SHA256" ]]
}

restore_binary_install() {
	local had_binary=$1
	local had_marker=$2
	local binary_backup=$3
	local marker_backup=$4

	if [[ $had_binary -eq 1 ]]; then
		sudo cp --preserve=mode,ownership,timestamps \
			"$binary_backup" \
			"$RYZENADJ_BINARY"
	else
		sudo rm -f -- "$RYZENADJ_BINARY"
	fi

	if [[ $had_marker -eq 1 ]]; then
		sudo cp --preserve=mode,ownership,timestamps \
			"$marker_backup" \
			"$INSTALL_MARKER"
	else
		sudo rm -f -- "$INSTALL_MARKER"
	fi
}

build_and_install_ryzenadj() {
	local archive="$temporary_dir/$RYZENADJ_VERSION.tar.gz"
	local source_tree="$temporary_dir/RyzenAdj-${RYZENADJ_VERSION#v}"
	local build_tree="$temporary_dir/build"
	local marker_source="$temporary_dir/ryzenadj-install"
	local binary_backup="$temporary_dir/ryzenadj.backup"
	local marker_backup="$temporary_dir/marker.backup"
	local binary_sha256
	local built_version
	local had_binary=0
	local had_marker=0

	log "Downloading RyzenAdj $RYZENADJ_VERSION"
	curl \
		--fail \
		--location \
		--silent \
		--show-error \
		--output "$archive" \
		"$RYZENADJ_SOURCE_URL"

	printf '%s  %s\n' "$RYZENADJ_SOURCE_SHA256" "$archive" |
		sha256sum --check --status ||
		error "RyzenAdj source checksum verification failed"

	tar -xzf "$archive" -C "$temporary_dir"

	log "Building RyzenAdj $RYZENADJ_VERSION"
	cmake \
		-S "$source_tree" \
		-B "$build_tree" \
		-DCMAKE_BUILD_TYPE=Release
	nice -n 10 cmake --build "$build_tree" --parallel 2

	built_version=$("$build_tree/ryzenadj" --help 2>&1 |
		awk '/^Version:/ { print $2; exit }')
	if [[ "$built_version" != "$RYZENADJ_VERSION" ]]; then
		error "Built unexpected RyzenAdj version: ${built_version:-unknown}"
	fi

	binary_sha256=$(sha256sum "$build_tree/ryzenadj" | awk '{ print $1 }')
	printf '%s\n' \
		"$MANAGED_HEADER" \
		"version=$RYZENADJ_VERSION" \
		"source_sha256=$RYZENADJ_SOURCE_SHA256" \
		"binary_sha256=$binary_sha256" >"$marker_source"

	if sudo test -f "$RYZENADJ_BINARY"; then
		sudo cp --preserve=mode,ownership,timestamps \
			"$RYZENADJ_BINARY" \
			"$binary_backup"
		had_binary=1
	fi

	if sudo test -f "$INSTALL_MARKER"; then
		sudo cp --preserve=mode,ownership,timestamps \
			"$INSTALL_MARKER" \
			"$marker_backup"
		had_marker=1
	fi

	log "Installing $RYZENADJ_BINARY"
	if ! sudo install -D -m 0755 \
		"$build_tree/ryzenadj" \
		"$RYZENADJ_BINARY" ||
		! sudo install -D -m 0644 \
			"$marker_source" \
			"$INSTALL_MARKER"; then
		log "Restoring the previous RyzenAdj installation"
		restore_binary_install \
			"$had_binary" \
			"$had_marker" \
			"$binary_backup" \
			"$marker_backup"
		error "Could not install RyzenAdj"
	fi
}

create_sudoers_source() {
	local setup_user=$1
	local source=$2

	printf '%s\n' \
		"$MANAGED_HEADER" \
		"$setup_user ALL=(root) NOPASSWD: $CONTROLLER_BINARY read, $CONTROLLER_BINARY apply, $CONTROLLER_BINARY auto" \
		>"$source"

	visudo -cf "$source" >/dev/null ||
		error "Generated invalid sudoers configuration"
}

require_command awk
require_command cmake
require_command cmp
require_command curl
require_command jq
require_command nice
require_command sha256sum
require_command systemctl
require_command tar
require_command visudo

require_source "$SOURCE_DIR/thinkpad-thermal"
require_source "$SOURCE_DIR/ryzenadj-power-saving.service"
require_source "$SOURCE_DIR/thinkpad-thermal-check.service"
require_source "$SOURCE_DIR/thinkpad-thermal-check.timer"

temporary_dir=$(mktemp -d)
trap 'rm -rf -- "$temporary_dir"' EXIT

setup_user=$(id -un)
if [[ "$setup_user" == "root" ]] || ! id "$setup_user" >/dev/null 2>&1; then
	error "Run setup as the desktop user, not as root"
fi

first_run=0
if ! sudo test -e "$APPLY_UNIT"; then
	first_run=1
fi

apply_enabled=$(systemctl is-enabled \
	ryzenadj-power-saving.service 2>/dev/null || true)
timer_enabled=$(systemctl is-enabled \
	thinkpad-thermal-check.timer 2>/dev/null || true)
timer_active=$(systemctl is-active \
	thinkpad-thermal-check.timer 2>/dev/null || true)

runtime_changed=0
units_changed=0

if ryzenadj_install_is_current; then
	log "$RYZENADJ_BINARY is current"
else
	build_and_install_ryzenadj
	runtime_changed=1
fi

if install_if_changed \
	"$SOURCE_DIR/thinkpad-thermal" \
	"$CONTROLLER_BINARY" \
	0755; then
	runtime_changed=1
else
	log "$CONTROLLER_BINARY is current"
fi

if install_if_changed \
	"$SOURCE_DIR/ryzenadj-power-saving.service" \
	"$APPLY_UNIT" \
	0644; then
	units_changed=1
fi

if install_if_changed \
	"$SOURCE_DIR/thinkpad-thermal-check.service" \
	"$CHECK_UNIT" \
	0644; then
	units_changed=1
fi

if install_if_changed \
	"$SOURCE_DIR/thinkpad-thermal-check.timer" \
	"$CHECK_TIMER" \
	0644; then
	units_changed=1
fi

sudoers_source="$temporary_dir/dotfiles-thinkpad-thermal"
create_sudoers_source "$setup_user" "$sudoers_source"
if install_if_changed "$sudoers_source" "$SUDOERS_FILE" 0440; then
	runtime_changed=1
else
	log "$SUDOERS_FILE is current"
fi

if [[ $units_changed -eq 1 ]]; then
	log "Reloading systemd units"
	sudo systemctl daemon-reload
fi

if [[ $first_run -eq 1 ]]; then
	log "Enabling RyzenAdj boot/resume application and status checks"
	sudo systemctl enable \
		ryzenadj-power-saving.service \
		thinkpad-thermal-check.timer

	if ! sudo systemctl start thinkpad-thermal-check.timer ||
		! sudo systemctl start ryzenadj-power-saving.service; then
		log "Rolling back first-run service enablement"
		sudo systemctl disable --now \
			thinkpad-thermal-check.timer \
			ryzenadj-power-saving.service || true
		error "Could not start RyzenAdj thermal-control services"
	fi

	exit 0
fi

if [[ $units_changed -eq 1 && "$timer_active" == "active" ]]; then
	log "Restarting the active status-check timer"
	sudo systemctl restart thinkpad-thermal-check.timer
fi

case "$apply_enabled" in
enabled | enabled-runtime)
	if [[ $runtime_changed -eq 1 || $units_changed -eq 1 ]]; then
		log "Reapplying RyzenAdj power-saving mode"
		sudo systemctl start ryzenadj-power-saving.service
	fi
	;;
*)
	log "Preserving $APPLY_UNIT state: $apply_enabled"
	;;
esac

case "$timer_enabled/$timer_active" in
enabled/active | enabled-runtime/active) ;;
*) log "Preserving $CHECK_TIMER state: $timer_enabled/$timer_active" ;;
esac
