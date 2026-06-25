#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_DIR=${DOTFILES_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}
PACKAGES_JSON="$SCRIPT_DIR/packages.json"
DRY_RUN=0
APT_UPDATED=0

usage() {
	cat <<EOF
Usage: setup/setup.sh [--dry-run]

Install applications declared in setup/packages.json.
EOF
}

log() {
	echo "setup/setup-applications - $*"
}

section() {
	echo ""
	log "$*"
}

error() {
	log "ERROR: $*" >&2
	exit 1
}

run() {
	if [[ $DRY_RUN -eq 1 ]]; then
		printf 'setup/setup-applications - dry-run:'
		printf ' %q' "$@"
		printf '\n'
	else
		"$@"
	fi
}

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		error "Missing required command: $1"
	fi
}

apt_is_installed() {
	local package=$1

	dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"
}

apt_has_candidate() {
	local package=$1
	local candidate

	candidate=$(apt-cache policy "$package" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')
	[[ -n "$candidate" && "$candidate" != "(none)" ]]
}

snap_is_installed() {
	local package=$1

	command -v snap >/dev/null 2>&1 && snap list "$package" >/dev/null 2>&1
}

apt_update_once() {
	if [[ $APT_UPDATED -eq 1 ]]; then
		return
	fi

	run sudo apt update
	APT_UPDATED=1
}

bootstrap_jq() {
	if command -v jq >/dev/null 2>&1; then
		return
	fi

	if [[ $DRY_RUN -eq 1 ]]; then
		error "jq is required for --dry-run"
	fi

	log "Installing jq bootstrap dependency"
	sudo apt update
	APT_UPDATED=1
	sudo apt install -y jq
}

bootstrap_setup_packages() {
	local missing=()
	local package

	for package in ca-certificates curl gnupg; do
		if ! apt_is_installed "$package"; then
			missing+=("$package")
		fi
	done

	if ((${#missing[@]} == 0)); then
		return
	fi

	if [[ $DRY_RUN -eq 1 ]]; then
		log "dry-run: would install setup dependencies: ${missing[*]}"
		return
	fi

	log "Installing setup dependencies: ${missing[*]}"
	apt_update_once
	sudo apt install -y "${missing[@]}"
}

ensure_ca_certificates() {
	if [[ $DRY_RUN -eq 1 ]]; then
		log "dry-run: would refresh CA certificates"
		return
	fi

	if command -v update-ca-certificates >/dev/null 2>&1; then
		sudo update-ca-certificates >/dev/null
	fi
}

json_array() {
	jq -r "$1" "$PACKAGES_JSON"
}

validate_hook() {
	local hook_rel=$1
	local hook_path
	local hook_abs
	local hooks_dir

	case "$hook_rel" in
	setup/hooks/*_hook.sh) ;;
	*) error "Invalid hook path: $hook_rel" ;;
	esac

	hook_path="$DOTFILES_DIR/$hook_rel"

	if [[ ! -f "$hook_path" ]]; then
		error "Hook not found: $hook_rel"
	fi

	hook_abs=$(readlink -f "$hook_path")
	hooks_dir=$(readlink -f "$SCRIPT_DIR/hooks")

	case "$hook_abs" in
	"$hooks_dir"/*) ;;
	*) error "Hook path escapes setup/hooks: $hook_rel" ;;
	esac
}

validate_manifest() {
	local duplicates
	local hook
	local package
	local plain_missing=()

	jq empty "$PACKAGES_JSON"

	duplicates=$(json_array '.apt[]?.package' | sort | uniq -d)
	if [[ -n "$duplicates" ]]; then
		error "Duplicate apt package entries: $(echo "$duplicates" | tr '\n' ' ')"
	fi

	duplicates=$(json_array '.snap[]?.package' | sort | uniq -d)
	if [[ -n "$duplicates" ]]; then
		error "Duplicate snap package entries: $(echo "$duplicates" | tr '\n' ' ')"
	fi

	duplicates=$(json_array '.flatpak[]?.package' | sort | uniq -d)
	if [[ -n "$duplicates" ]]; then
		error "Duplicate flatpak package entries: $(echo "$duplicates" | tr '\n' ' ')"
	fi

	while IFS= read -r hook; do
		[[ -n "$hook" ]] || continue
		validate_hook "$hook"
	done < <(json_array '[.apt[]?.hooks[]?, .snap[]?.hooks[]?, .flatpak[]?.hooks[]?] | unique[]')

	if [[ $DRY_RUN -eq 1 ]]; then
		while IFS= read -r package; do
			[[ -n "$package" ]] || continue
			if ! apt_has_candidate "$package"; then
				plain_missing+=("$package")
			fi
		done < <(jq -r '.apt[]? | select(has("source-file") | not) | select(.optional != true) | .package' "$PACKAGES_JSON")

		if ((${#plain_missing[@]})); then
			error "Required apt packages without candidates: ${plain_missing[*]}"
		fi
	fi
}

source_content_matches() {
	local current_content=$1
	local source_content=$2
	local entry=$3
	local encoded
	local alternate_content

	if [[ "$current_content" == "$source_content" ]]; then
		return 0
	fi

	while IFS= read -r encoded; do
		[[ -n "$encoded" ]] || continue
		alternate_content=$(printf '%s' "$encoded" | base64 --decode)
		if [[ "$current_content" == "$alternate_content" ]]; then
			return 0
		fi
	done < <(jq -r '."source-content-alternates"[]? | @base64' <<<"$entry")

	return 1
}

configure_apt_repositories() {
	local entry
	local package
	local gpg_key
	local gpg_key_format
	local signed_by
	local source_file
	local source_content
	local current_content
	local repo_changed=0
	local package_changed

	section "Configuring apt repositories"

	while IFS= read -r entry; do
		package_changed=0
		package=$(jq -r '.package' <<<"$entry")
		gpg_key=$(jq -r '."gpg-key" // empty' <<<"$entry")
		gpg_key_format=$(jq -r '."gpg-key-format" // "dearmor"' <<<"$entry")
		signed_by=$(jq -r '."signed-by" // empty' <<<"$entry")
		source_file=$(jq -r '."source-file" // empty' <<<"$entry")
		source_content=$(jq -r '."source-content" // empty' <<<"$entry")

		if [[ -z "$gpg_key" && -z "$source_file" && -z "$source_content" && -z "$signed_by" ]]; then
			continue
		fi

		if [[ -z "$gpg_key" || -z "$signed_by" || -z "$source_file" || -z "$source_content" ]]; then
			error "$package repo metadata must include gpg-key, signed-by, source-file, and source-content"
		fi

		if [[ ! -f "$signed_by" ]]; then
			if [[ $DRY_RUN -eq 1 ]]; then
				log "dry-run: would add apt key for $package at $signed_by"
				package_changed=1
			else
				sudo install -d -m 0755 "$(dirname -- "$signed_by")"
				log "Adding apt key for $package"
				case "$gpg_key_format" in
				ascii)
					curl --fail --location --show-error --silent "$gpg_key" | sudo tee "$signed_by" >/dev/null
					;;
				dearmor)
					curl --fail --location --show-error --silent "$gpg_key" | sudo gpg --dearmor --yes -o "$signed_by"
					;;
				*) error "Unsupported gpg-key-format for $package: $gpg_key_format" ;;
				esac
				repo_changed=1
			fi
		fi

		current_content=$(cat "$source_file" 2>/dev/null || true)
		if ! source_content_matches "$current_content" "$source_content" "$entry"; then
			if [[ $DRY_RUN -eq 1 ]]; then
				log "dry-run: would write apt source for $package at $source_file"
				package_changed=1
			else
				sudo install -d -m 0755 "$(dirname -- "$source_file")"
				log "Writing apt source for $package"
				printf '%s\n' "$source_content" | sudo tee "$source_file" >/dev/null
				repo_changed=1
			fi
		fi

		if [[ $DRY_RUN -eq 1 ]]; then
			if [[ $package_changed -eq 1 ]]; then
				repo_changed=1
			else
				log "$package apt repo already configured"
			fi
		fi
	done < <(jq -c '.apt[]?' "$PACKAGES_JSON")

	if [[ $repo_changed -eq 1 ]]; then
		apt_update_once
	elif [[ $DRY_RUN -eq 1 ]]; then
		log "apt repositories already configured"
	fi
}

install_apt_packages() {
	local missing=()
	local optional=()
	local package

	section "Installing apt packages"

	while IFS= read -r package; do
		[[ -n "$package" ]] || continue
		if ! apt_is_installed "$package"; then
			missing+=("$package")
		fi
	done < <(json_array '.apt[]? | select(.optional != true) | .package')

	mapfile -t optional < <(json_array '.apt[]? | select(.optional == true) | .package')

	if ((${#missing[@]})); then
		if [[ $DRY_RUN -eq 1 ]]; then
			log "dry-run: would install apt packages: ${missing[*]}"
		else
			apt_update_once
			sudo apt install -y "${missing[@]}"
		fi
	else
		log "apt packages already installed"
	fi

	for package in "${optional[@]}"; do
		if apt_is_installed "$package"; then
			log "optional apt package already installed: $package"
			continue
		fi

		if [[ $DRY_RUN -eq 1 ]]; then
			log "dry-run: would install optional apt package: $package"
			continue
		fi

		apt_update_once
		sudo apt install -y "$package" || log "WARN: optional apt package failed: $package"
	done
}

install_snap_packages() {
	local entry
	local package
	local command_name
	local apt_package

	if ! jq -e '.snap | length > 0' "$PACKAGES_JSON" >/dev/null; then
		return
	fi

	section "Installing snap packages"

	if [[ $DRY_RUN -eq 1 ]]; then
		log "dry-run: would ensure snapd is available if snap packages are needed"
	elif ! command -v snap >/dev/null 2>&1; then
		log "Installing snapd"
		apt_update_once
		sudo apt install -y snapd
	fi

	while IFS= read -r entry; do
		package=$(jq -r '.package' <<<"$entry")
		command_name=$(jq -r '.command // empty' <<<"$entry")
		apt_package=$(jq -r '."apt-package" // empty' <<<"$entry")

		if [[ $DRY_RUN -eq 1 ]]; then
			if [[ -n "$command_name" ]] && command -v "$command_name" >/dev/null 2>&1; then
				log "$package already installed"
				continue
			fi

			if [[ -n "$apt_package" ]] && apt_has_candidate "$apt_package"; then
				log "dry-run: would install apt fallback for $package: $apt_package"
				continue
			fi

			log "dry-run: would install snap package: $package"
			continue
		fi

		if snap_is_installed "$package"; then
			log "$package snap already installed"
			continue
		fi

		if [[ -n "$command_name" ]] && command -v "$command_name" >/dev/null 2>&1; then
			log "$package already installed"
			continue
		fi

		if [[ -n "$apt_package" ]] && apt_has_candidate "$apt_package"; then
			apt_update_once
			sudo apt install -y "$apt_package"
			continue
		fi

		sudo snap install "$package"
	done < <(jq -c '.snap[]?' "$PACKAGES_JSON")
}

install_flatpak_packages() {
	local package
	local installed

	if ! jq -e '.flatpak | length > 0' "$PACKAGES_JSON" >/dev/null; then
		return
	fi

	section "Installing flatpak packages"

	if [[ $DRY_RUN -eq 1 ]]; then
		log "dry-run: would ensure flatpak and flathub are available"
	else
		if ! command -v flatpak >/dev/null 2>&1; then
			apt_update_once
			sudo apt install -y flatpak
		fi
		flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
	fi

	installed=$(flatpak list --app --columns=application 2>/dev/null || true)

	while IFS= read -r package; do
		[[ -n "$package" ]] || continue
		if printf '%s\n' "$installed" | grep -qx "$package"; then
			log "$package already installed"
		elif [[ $DRY_RUN -eq 1 ]]; then
			log "dry-run: would install flatpak package: $package"
		else
			flatpak install --user --noninteractive --assumeyes flathub "$package"
		fi
	done < <(json_array '.flatpak[]?.package')
}

install_mise() {
	local mise_bin
	local runtimes=()
	local runtime
	local ca_file=/etc/ssl/certs/ca-certificates.crt

	if ! jq -e '.mise // false' "$PACKAGES_JSON" >/dev/null; then
		return
	fi

	section "Installing mise runtimes"

	mapfile -t runtimes < <(jq -r 'if (.mise | type) == "object" then .mise.runtimes[]? else empty end' "$PACKAGES_JSON")

	if [[ $DRY_RUN -eq 1 ]]; then
		log "dry-run: would install mise if missing"
		if ((${#runtimes[@]})); then
			log "dry-run: would install mise runtimes: ${runtimes[*]}"
		fi
		return
	fi

	if ! command -v mise >/dev/null 2>&1 && [[ ! -x "$HOME/.local/bin/mise" ]]; then
		if [[ ! -r "$ca_file" ]]; then
			error "CA certificate bundle is missing: $ca_file"
		fi

		ensure_ca_certificates
		(
			export CURL_CA_BUNDLE="$ca_file"
			export MISE_INSTALL_FROM_GITHUB=1
			export MISE_INSTALL_PATH="$HOME/.local/bin/mise"
			export SSL_CERT_FILE="$ca_file"
			curl --fail --location --show-error https://mise.run | sh
		)
	fi

	mise_bin=$(command -v mise || true)
	if [[ -z "$mise_bin" && -x "$HOME/.local/bin/mise" ]]; then
		mise_bin="$HOME/.local/bin/mise"
	fi

	if [[ -z "$mise_bin" ]]; then
		error "mise install completed but mise is not available"
	fi

	for runtime in "${runtimes[@]}"; do
		"$mise_bin" install "$runtime"
	done
}

run_hooks() {
	local hook
	local hook_path

	section "Running hooks"

	while IFS= read -r hook; do
		[[ -n "$hook" ]] || continue
		validate_hook "$hook"
		hook_path="$DOTFILES_DIR/$hook"

		if [[ $DRY_RUN -eq 1 ]]; then
			log "dry-run: would run hook: $hook"
		else
			DOTFILES_DIR="$DOTFILES_DIR" SETUP_DIR="$SCRIPT_DIR" PACKAGES_JSON="$PACKAGES_JSON" bash "$hook_path"
		fi
	done < <(json_array '[.apt[]?.hooks[]?, .snap[]?.hooks[]?, .flatpak[]?.hooks[]?] | unique[]')
}

case "${1:-}" in
"") ;;
--dry-run)
	DRY_RUN=1
	;;
-h | --help)
	usage
	exit 0
	;;
*)
	usage >&2
	error "Unknown option: $1"
	;;
esac

if [[ ! -f "$PACKAGES_JSON" ]]; then
	error "packages.json not found"
fi

bootstrap_jq
require_command apt-cache
require_command awk
require_command sort
require_command uniq

validate_manifest
bootstrap_setup_packages
configure_apt_repositories
install_apt_packages
install_snap_packages
install_flatpak_packages
install_mise
run_hooks

echo ""
log "✓"
