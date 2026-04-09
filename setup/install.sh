#!/bin/bash
# Distro setup for Fedora Sway Atomic.
#
# Reads setup/packages.json and applies host changes idempotently:
#   1. rpm-ostree   — layer / unlayer packages
#   2. distrobox    — create containers, install + export packages
#   3. flatpak      — install missing apps from Flathub
#   4. systemd-user — enable user services (built-in + custom)
#
# Run after config/install.sh (which symlinks dotfiles, including the
# custom systemd unit files this script enables).
#
# Fails hard if any required tool is missing — this script assumes a
# Fedora Atomic host with rpm-ostree, distrobox, flatpak, and systemctl
# already present.

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PACKAGES_JSON="$SCRIPT_DIR/packages.json"

if [[ ! -f "$PACKAGES_JSON" ]]; then
	echo "setup/install - ERROR: packages.json not found" >&2
	exit 1
fi

require_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "setup/install - ERROR: required command '$1' not found" >&2
		exit 1
	fi
}

require_cmd jq
require_cmd rpm-ostree
require_cmd flatpak
require_cmd systemctl

NEEDS_REBOOT=0
log() { echo "setup/install - $*"; }
section() { echo; echo "==> $*"; }

#-------------------------------------------------------------------------------
# 1. rpm-ostree — layer / remove host packages
#-------------------------------------------------------------------------------
section "rpm-ostree"

status_json=$(rpm-ostree status --json)

# Currently layered packages
currently_layered=$(printf '%s' "$status_json" | jq -r '.deployments[0]."requested-packages"[]?' | sort -u)
# Currently removed (overridden out) base packages
currently_removed=$(printf '%s' "$status_json" | jq -r '.deployments[0]."requested-base-removals"[]?' | sort -u)

desired_install=$(jq -r '."rpm-ostree".install[].package' "$PACKAGES_JSON" | sort -u)
desired_remove=$(jq -r '."rpm-ostree".remove[].package' "$PACKAGES_JSON" | sort -u)

to_install=$(comm -23 <(printf '%s\n' "$desired_install") <(printf '%s\n' "$currently_layered") | grep -v '^$' || true)
to_remove=$(comm -23 <(printf '%s\n' "$desired_remove") <(printf '%s\n' "$currently_removed") | grep -v '^$' || true)

if [[ -n "$to_remove" ]]; then
	log "removing base packages: $(echo "$to_remove" | tr '\n' ' ')"
	# shellcheck disable=SC2086
	sudo rpm-ostree override remove $to_remove
	NEEDS_REBOOT=1
else
	log "no base packages to remove"
fi

if [[ -n "$to_install" ]]; then
	log "layering packages: $(echo "$to_install" | tr '\n' ' ')"
	# shellcheck disable=SC2086
	sudo rpm-ostree install $to_install
	NEEDS_REBOOT=1
else
	log "no packages to layer"
fi

#-------------------------------------------------------------------------------
# 2. distrobox — create containers, install packages, export
#-------------------------------------------------------------------------------
section "distrobox"

# distrobox is layered via rpm-ostree, so it requires a reboot to become
# available. If we just staged that layering, surface the situation clearly.
if ! command -v distrobox >/dev/null 2>&1; then
	if [[ $NEEDS_REBOOT -eq 1 ]]; then
		echo "setup/install - ERROR: distrobox not on PATH yet — reboot to apply rpm-ostree changes, then re-run" >&2
	else
		echo "setup/install - ERROR: distrobox not found on PATH" >&2
	fi
	exit 1
fi

mapfile -t containers < <(jq -r '.distrobox | keys[]' "$PACKAGES_JSON")

for container in "${containers[@]}"; do
	image=$(jq -r --arg c "$container" '.distrobox[$c].image' "$PACKAGES_JSON")

	if distrobox list | awk 'NR>1 {print $3}' | grep -qx "$container"; then
		log "container '$container' already exists"
	else
		log "creating container '$container' from $image"
		distrobox create --yes --name "$container" --image "$image"
	fi

	# Install missing packages inside the container.
	mapfile -t pkgs < <(jq -r --arg c "$container" '.distrobox[$c].packages[].package' "$PACKAGES_JSON")
	if [[ ${#pkgs[@]} -gt 0 ]]; then
		# shellcheck disable=SC2016
		missing=$(distrobox enter "$container" -- bash -c '
			missing=()
			for pkg in "$@"; do
				rpm -q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
			done
			printf "%s\n" "${missing[@]}"
		' -- "${pkgs[@]}" | grep -v '^$' || true)

		if [[ -n "$missing" ]]; then
			log "[$container] installing: $(echo "$missing" | tr '\n' ' ')"
			# shellcheck disable=SC2086
			distrobox enter "$container" -- sudo dnf install -y $missing
		else
			log "[$container] all packages already installed"
		fi
	fi

	# Export apps (.desktop entries).
	mapfile -t export_apps < <(jq -r --arg c "$container" '.distrobox[$c]["export-apps"][]?' "$PACKAGES_JSON")
	for app in "${export_apps[@]}"; do
		distrobox enter "$container" -- distrobox-export --app "$app" >/dev/null 2>&1 || \
			log "[$container] WARN: could not export app '$app'"
	done
	[[ ${#export_apps[@]} -gt 0 ]] && log "[$container] exported ${#export_apps[@]} apps"

	# Export binaries.
	mapfile -t export_bins < <(jq -r --arg c "$container" '.distrobox[$c]["export-bins"][]?' "$PACKAGES_JSON")
	for bin in "${export_bins[@]}"; do
		distrobox enter "$container" -- distrobox-export --bin "$bin" --export-path "$HOME/.local/bin" >/dev/null 2>&1 || \
			log "[$container] WARN: could not export bin '$bin'"
	done
	[[ ${#export_bins[@]} -gt 0 ]] && log "[$container] exported ${#export_bins[@]} bins"
done

#-------------------------------------------------------------------------------
# 3. flatpak
#-------------------------------------------------------------------------------
section "flatpak"

flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo

mapfile -t flatpaks < <(jq -r '.flatpak[].package' "$PACKAGES_JSON")
installed=$(flatpak list --app --columns=application 2>/dev/null || true)

for app in "${flatpaks[@]}"; do
	if printf '%s\n' "$installed" | grep -qx "$app"; then
		log "$app already installed"
	else
		log "installing $app"
		flatpak install --user --noninteractive --assumeyes flathub "$app"
	fi
done

#-------------------------------------------------------------------------------
# 4. systemd user services
#-------------------------------------------------------------------------------
section "systemd-user"

# Built-in sockets (ssh-agent, podman, etc.)
mapfile -t builtin_units < <(jq -r '."systemd-user".enable[]' "$PACKAGES_JSON")
for unit in "${builtin_units[@]}"; do
	if systemctl --user is-enabled "$unit" >/dev/null 2>&1; then
		log "$unit already enabled"
	else
		log "enabling $unit"
		systemctl --user enable --now "$unit"
	fi
done

# Custom unit files (symlinked from config/systemd by config/install.sh).
mapfile -t custom_units < <(jq -r '."systemd-user"."enable-custom"[].service' "$PACKAGES_JSON")
for unit in "${custom_units[@]}"; do
	unit_path="$HOME/.config/systemd/user/$unit"
	if [[ ! -e "$unit_path" ]]; then
		echo "setup/install - ERROR: $unit not found at $unit_path — run config/install.sh first" >&2
		exit 1
	fi
	if systemctl --user is-enabled "$unit" >/dev/null 2>&1; then
		log "$unit already enabled"
	else
		log "enabling $unit"
		systemctl --user enable --now "$unit"
	fi
done

#-------------------------------------------------------------------------------
# Done
#-------------------------------------------------------------------------------
echo
if [[ $NEEDS_REBOOT -eq 1 ]]; then
	echo -e "\033[33msetup/install - rpm-ostree changes staged. Reboot required.\033[0m"
fi
echo -e "setup/install - \033[32m✓ done\033[0m"
