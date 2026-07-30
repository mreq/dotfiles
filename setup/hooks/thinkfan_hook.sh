#!/bin/bash

set -euo pipefail

DOTFILES_DIR=${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
SOURCE_DIR="$DOTFILES_DIR/config/thinkfan"

THINKFAN_CONFIG=/etc/thinkfan.yaml
MODULE_CONFIG=/etc/modprobe.d/thinkfan.conf
FAN_CONTROL_PARAMETER=/sys/module/thinkpad_acpi/parameters/fan_control
FAN_INTERFACE=/proc/acpi/ibm/fan
MANAGED_HEADER="# Managed by dotfiles: setup/hooks/thinkfan_hook.sh"

log() {
	echo "setup/hooks/thinkfan_hook - $*"
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

	if sudo test -f "$target" && sudo cmp -s "$source" "$target"; then
		return 1
	fi

	log "Installing $target"
	sudo install -D -m 0644 "$source" "$target"
	return 0
}

reject_conflicting_module_settings() {
	local file

	if grep -Eiq \
		'(^|[[:space:]])thinkpad_acpi\.fan_control=(0|n|no|false)([[:space:]]|$)' \
		/proc/cmdline; then
		error "The active kernel command line disables thinkpad_acpi fan control"
	fi

	for file in /etc/modprobe.d/*.conf /usr/lib/modprobe.d/*.conf; do
		[[ -f "$file" ]] || continue
		[[ "$file" == "$MODULE_CONFIG" ]] && continue

		if grep -Eiq \
			'^[[:space:]]*options[[:space:]]+thinkpad_acpi.*fan_control[[:space:]]*=[[:space:]]*(0|n|no|false)([[:space:]#]|$)' \
			"$file"; then
			error "Conflicting fan_control setting in $file"
		fi
	done
}

install_module_config() {
	local source="$temporary_dir/thinkfan.conf"
	local backup="$temporary_dir/module-config.backup"
	local had_previous=0
	local kernel_release

	printf '%s\n%s\n' \
		"$MANAGED_HEADER" \
		"options thinkpad_acpi fan_control=1" >"$source"

	require_managed_or_absent "$MODULE_CONFIG"

	if sudo test -f "$MODULE_CONFIG" && sudo cmp -s "$source" "$MODULE_CONFIG"; then
		log "$MODULE_CONFIG is current"
		return
	fi

	if sudo test -f "$MODULE_CONFIG"; then
		sudo cp --preserve=mode,ownership,timestamps "$MODULE_CONFIG" "$backup"
		had_previous=1
	fi

	log "Installing $MODULE_CONFIG"
	sudo install -D -m 0644 "$source" "$MODULE_CONFIG"

	kernel_release=$(uname -r)
	log "Updating initramfs for $kernel_release"
	if sudo update-initramfs -u -k "$kernel_release"; then
		return
	fi

	log "Restoring the previous module configuration after initramfs failure"
	if [[ $had_previous -eq 1 ]]; then
		sudo install -D -m 0644 "$backup" "$MODULE_CONFIG"
	else
		sudo rm -f -- "$MODULE_CONFIG"
	fi
	sudo update-initramfs -u -k "$kernel_release" || true
	error "Could not persist thinkpad_acpi fan control"
}

restore_firmware_auto() {
	if ! sudo test -w "$FAN_INTERFACE"; then
		return
	fi

	printf '%s\n' "level auto" | sudo tee "$FAN_INTERFACE" >/dev/null
	printf '%s\n' "watchdog 0" | sudo tee "$FAN_INTERFACE" >/dev/null
}

live_fan_control_available() {
	[[ -r "$FAN_CONTROL_PARAMETER" ]] &&
		[[ "$(<"$FAN_CONTROL_PARAMETER")" == "Y" ]] &&
		sudo test -w "$FAN_INTERFACE"
}

require_command cmp
require_command grep
require_command systemctl
require_command thinkfan
require_command update-initramfs

require_source "$SOURCE_DIR/thinkfan.yaml"

require_managed_or_absent "$THINKFAN_CONFIG"
reject_conflicting_module_settings

first_run=0
if ! sudo test -e "$THINKFAN_CONFIG"; then
	first_run=1
fi

service_enabled=$(systemctl is-enabled thinkfan.service 2>/dev/null || true)
service_active=$(systemctl is-active thinkfan.service 2>/dev/null || true)
config_changed=0

temporary_dir=$(mktemp -d)
trap 'rm -rf -- "$temporary_dir"' EXIT

install_module_config

if install_if_changed "$SOURCE_DIR/thinkfan.yaml" "$THINKFAN_CONFIG"; then
	config_changed=1
else
	log "$THINKFAN_CONFIG is current"
fi

if [[ $first_run -eq 1 ]]; then
	if [[ "$service_enabled" == "masked" || "$service_enabled" == "masked-runtime" ]]; then
		log "thinkfan.service is masked; leaving it masked"
		exit 0
	fi

	log "Enabling thinkfan.service and its sleep/wakeup helpers"
	sudo systemctl enable thinkfan.service

	if ! live_fan_control_available; then
		log "Fan control is not active in the running kernel; Thinkfan will start after reboot"
		exit 0
	fi

	if [[ "$service_active" == "active" ]]; then
		log "Reloading the already-active thinkfan.service"
		service_action=reload
	else
		log "Starting thinkfan.service"
		service_action=start
	fi

	if ! sudo systemctl "$service_action" thinkfan.service; then
		sudo systemctl disable thinkfan.service || true
		restore_firmware_auto
		error "Thinkfan failed to $service_action; service enablement was rolled back"
	fi

	exit 0
fi

if [[ $config_changed -eq 1 && "$service_active" == "active" ]]; then
	log "Reloading the already-active thinkfan.service"
	if ! sudo systemctl reload thinkfan.service; then
		restore_firmware_auto
		error "Thinkfan failed to reload; firmware fan control was restored"
	fi
elif [[ $config_changed -eq 1 ]]; then
	log "Preserving thinkfan.service state: $service_enabled/$service_active"
else
	log "Thinkfan configuration and service state are unchanged"
fi
