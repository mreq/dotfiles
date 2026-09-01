#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_DIR=${DOTFILES_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}
PACKAGES_JSON="$SCRIPT_DIR/packages.json"
DRY_RUN=0
APT_UPDATED=0
DMI_PRODUCT_FAMILY=

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

trim_filter_value() {
	local value=$1

	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	printf '%s' "$value"
}

read_dmi_product_family() {
	local dmi_id_dir=$1
	local product_family_file="$dmi_id_dir/product_family"
	local value

	if [[ ! -r "$product_family_file" ]]; then
		return
	fi

	IFS= read -r value <"$product_family_file" || true
	trim_filter_value "$value"
}

manifest_filter_errors() {
	local manifest=$1

	jq -r '
		def entries:
			.apt[]?,
			.apt[]?.subpackages[]?,
			.snap[]?,
			.flatpak[]?;
		def entry_name:
			.package // "<unnamed>";
		def trim:
			gsub("^\\s+|\\s+$"; "");

		entries
		| select(has("filter"))
		| if (.filter | type) != "object" then
				"\(entry_name): filter must be an object"
			elif (.filter | length) == 0 then
				"\(entry_name): filter must not be empty"
			elif (((.filter | keys_unsorted) - ["dmi"]) | length) > 0 then
				"\(entry_name): filter supports only the dmi group"
			elif (.filter | has("dmi") | not) then
				"\(entry_name): filter must contain dmi"
			elif (.filter.dmi | type) != "object" then
				"\(entry_name): filter.dmi must be an object"
			elif (.filter.dmi | length) == 0 then
				"\(entry_name): filter.dmi must not be empty"
			elif (((.filter.dmi | keys_unsorted) - ["product_family"]) | length) > 0 then
				"\(entry_name): filter.dmi supports only product_family"
			elif (.filter.dmi | has("product_family") | not) then
				"\(entry_name): filter.dmi must contain product_family"
			elif (.filter.dmi.product_family | type) != "string" then
				"\(entry_name): filter.dmi.product_family must be a string"
			elif (.filter.dmi.product_family | trim | length) == 0 then
				"\(entry_name): filter.dmi.product_family must not be blank"
			else
				empty
			end
	' "$manifest"
}

filtered_package_entries() {
	local manifest=$1
	local package_type=$2
	local dmi_product_family=$3

	jq -c \
		--arg package_type "$package_type" \
		--arg dmi_product_family "$dmi_product_family" '
			def trim:
				gsub("^\\s+|\\s+$"; "");
			def matches_filter:
				if has("filter") | not then
					true
				elif $dmi_product_family == "" then
					false
				else
					(.filter.dmi.product_family | trim) == $dmi_product_family
				end;

			.[$package_type][]?
			| select(matches_filter)
		' "$manifest"
}

filtered_apt_package_entries() {
	local manifest=$1
	local dmi_product_family=$2

	jq -c \
		--arg dmi_product_family "$dmi_product_family" '
			def trim:
				gsub("^\\s+|\\s+$"; "");
			def matches_filter:
				if has("filter") | not then
					true
				elif $dmi_product_family == "" then
					false
				else
					(.filter.dmi.product_family | trim) == $dmi_product_family
				end;

			.apt[]? as $entry
			| select($entry | matches_filter)
			| $entry,
				(
					$entry.subpackages[]?
					| select(matches_filter)
					| . + { optional: (.optional // $entry.optional // false) }
				)
		' "$manifest"
}

manifest_filter_decisions() {
	local manifest=$1
	local dmi_product_family=$2

	jq -r \
		--arg dmi_product_family "$dmi_product_family" '
			def trim:
				gsub("^\\s+|\\s+$"; "");
			def matches_filter:
				if has("filter") | not then
					true
				elif $dmi_product_family == "" then
					false
				else
					(.filter.dmi.product_family | trim) == $dmi_product_family
				end;
			def decision($entry; $parent_matches):
				$entry
				| select(has("filter"))
				| [
					.package,
					(
						if $parent_matches and matches_filter
						then "matched"
						else "skipped"
						end
					),
					(.filter.dmi.product_family | trim)
				];

			(
				.apt[]? as $parent
				| decision($parent; true),
					(
						$parent.subpackages[]?
						| decision(.; ($parent | matches_filter))
					)
			),
			(.snap[]? | decision(.; true)),
			(.flatpak[]? | decision(.; true))
			| @tsv
		' "$manifest"
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

apt_matches_candidate() {
	local package=$1
	local candidate
	local installed

	candidate=$(apt-cache policy "$package" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')
	installed=$(dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true)

	[[ -n "$installed" && -n "$candidate" && "$candidate" != "(none)" && "$installed" == "$candidate" ]]
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

apt_package_entries() {
	filtered_apt_package_entries "$PACKAGES_JSON" "$DMI_PRODUCT_FAMILY"
}

all_apt_package_entries() {
	jq -c '
		.apt[]? as $entry
		| $entry,
			($entry.subpackages[]? | . + { optional: (.optional // $entry.optional // false) })
	' "$PACKAGES_JSON"
}

package_entries() {
	local package_type=$1

	filtered_package_entries "$PACKAGES_JSON" "$package_type" "$DMI_PRODUCT_FAMILY"
}

selected_hooks() {
	{
		package_entries apt
		package_entries snap
		package_entries flatpak
	} | jq -r '.hooks[]?' | sort -u
}

log_filter_decisions() {
	local package
	local decision
	local expected

	if [[ $DRY_RUN -ne 1 ]]; then
		return
	fi

	while IFS=$'\t' read -r package decision expected; do
		[[ -n "$package" ]] || continue
		log "hardware filter $decision: $package (DMI product_family: $expected)"
	done < <(manifest_filter_decisions "$PACKAGES_JSON" "$DMI_PRODUCT_FAMILY")
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
	local filter_errors

	jq empty "$PACKAGES_JSON"

	filter_errors=$(manifest_filter_errors "$PACKAGES_JSON")
	if [[ -n "$filter_errors" ]]; then
		error "Invalid package filters: ${filter_errors//$'\n'/; }"
	fi

	duplicates=$(all_apt_package_entries | jq -r '.package' | sort | uniq -d)
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
	done < <(selected_hooks)

	if [[ $DRY_RUN -eq 1 ]]; then
		while IFS= read -r package; do
			[[ -n "$package" ]] || continue
			if ! apt_has_candidate "$package"; then
				plain_missing+=("$package")
			fi
		done < <(apt_package_entries | jq -r 'select(has("source-file") | not) | select(.optional != true) | .package')

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

cleanup_obsolete_apt_configuration() {
	local entry
	local package
	local preferences_file
	local source_file
	local obsolete_preferences_file
	local obsolete_source_file
	local changed=0

	while IFS= read -r entry; do
		package=$(jq -r '.package' <<<"$entry")
		preferences_file=$(jq -r '."preferences-file" // empty' <<<"$entry")
		source_file=$(jq -r '."source-file" // empty' <<<"$entry")

		while IFS= read -r obsolete_source_file; do
			[[ -n "$obsolete_source_file" ]] || continue
			if [[ -n "$source_file" && "$obsolete_source_file" == "$source_file" ]]; then
				error "$package obsolete-source-files must not include source-file: $source_file"
			fi

			if [[ ! -e "$obsolete_source_file" ]]; then
				continue
			fi

			if [[ $DRY_RUN -eq 1 ]]; then
				log "dry-run: would remove obsolete apt source for $package at $obsolete_source_file"
			else
				log "Removing obsolete apt source for $package at $obsolete_source_file"
				sudo rm -f -- "$obsolete_source_file"
			fi
			changed=1
		done < <(jq -r '."obsolete-source-files"[]?' <<<"$entry")

		while IFS= read -r obsolete_preferences_file; do
			[[ -n "$obsolete_preferences_file" ]] || continue
			if [[ -n "$preferences_file" && "$obsolete_preferences_file" == "$preferences_file" ]]; then
				error "$package obsolete-preferences-files must not include preferences-file: $preferences_file"
			fi

			if [[ ! -e "$obsolete_preferences_file" ]]; then
				continue
			fi

			if [[ $DRY_RUN -eq 1 ]]; then
				log "dry-run: would remove obsolete apt preferences for $package at $obsolete_preferences_file"
			else
				log "Removing obsolete apt preferences for $package at $obsolete_preferences_file"
				sudo rm -f -- "$obsolete_preferences_file"
			fi
			changed=1
		done < <(jq -r '."obsolete-preferences-files"[]?' <<<"$entry")
	done < <(package_entries apt)

	if [[ $changed -eq 1 ]]; then
		return 0
	fi
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
	local preferences_file
	local preferences_content
	local current_preferences
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
		preferences_file=$(jq -r '."preferences-file" // empty' <<<"$entry")
		preferences_content=$(jq -r '."preferences-content" // empty' <<<"$entry")

		if [[ -z "$gpg_key" && -z "$source_file" && -z "$source_content" && -z "$signed_by" && -z "$preferences_file" && -z "$preferences_content" ]]; then
			continue
		fi

		if [[ -n "$gpg_key" || -n "$source_file" || -n "$source_content" || -n "$signed_by" ]]; then
			if [[ -z "$gpg_key" || -z "$signed_by" || -z "$source_file" || -z "$source_content" ]]; then
				error "$package repo metadata must include gpg-key, signed-by, source-file, and source-content"
			fi
		fi

		if [[ -n "$signed_by" && ! -f "$signed_by" ]]; then
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

		current_content=
		if [[ -n "$source_file" ]]; then
			current_content=$(cat "$source_file" 2>/dev/null || true)
		fi
		if [[ -n "$source_file" ]] && ! source_content_matches "$current_content" "$source_content" "$entry"; then
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

		if [[ -n "$preferences_file" || -n "$preferences_content" ]]; then
			if [[ -z "$preferences_file" || -z "$preferences_content" ]]; then
				error "$package apt preferences must include preferences-file and preferences-content"
			fi

			current_preferences=$(cat "$preferences_file" 2>/dev/null || true)
			if [[ "$current_preferences" != "$preferences_content" ]]; then
				if [[ $DRY_RUN -eq 1 ]]; then
					log "dry-run: would write apt preferences for $package at $preferences_file"
					package_changed=1
				else
					sudo install -d -m 0755 "$(dirname -- "$preferences_file")"
					log "Writing apt preferences for $package"
					printf '%s\n' "$preferences_content" | sudo tee "$preferences_file" >/dev/null
					repo_changed=1
				fi
			fi
		fi

		if [[ $DRY_RUN -eq 1 ]]; then
			if [[ $package_changed -eq 1 ]]; then
				repo_changed=1
			else
				log "$package apt repo already configured"
			fi
		fi
	done < <(package_entries apt)

	if cleanup_obsolete_apt_configuration; then
		repo_changed=1
	fi

	if [[ $repo_changed -eq 1 ]]; then
		APT_UPDATED=0
		apt_update_once
	elif [[ $DRY_RUN -eq 1 ]]; then
		log "apt repositories already configured"
	fi
}

install_apt_packages() {
	local entry
	local ensure_candidate_flag
	local missing=()
	local missing_no_recommends=()
	local no_recommends_flag
	local optional=()
	local optional_flag
	local package
	local reconcile=()

	section "Installing apt packages"

	while IFS= read -r entry; do
		package=$(jq -r '.package' <<<"$entry")
		ensure_candidate_flag=$(jq -r '."ensure-candidate" // false' <<<"$entry")
		no_recommends_flag=$(jq -r '."no-install-recommends" // false' <<<"$entry")
		optional_flag=$(jq -r '.optional // false' <<<"$entry")
		[[ -n "$package" ]] || continue

		if [[ "$optional_flag" == "true" ]]; then
			optional+=("$package")
		elif [[ "$ensure_candidate_flag" == "true" ]] && { [[ $DRY_RUN -eq 1 ]] || ! apt_matches_candidate "$package"; }; then
			reconcile+=("$package")
		elif [[ "$no_recommends_flag" == "true" ]] && ! apt_is_installed "$package"; then
			missing_no_recommends+=("$package")
		elif ! apt_is_installed "$package"; then
			missing+=("$package")
		fi
	done < <(apt_package_entries)

	if ((${#missing_no_recommends[@]})); then
		if [[ $DRY_RUN -eq 1 ]]; then
			log "dry-run: would install apt packages without recommends: ${missing_no_recommends[*]}"
		else
			apt_update_once
			sudo apt install -y --no-install-recommends "${missing_no_recommends[@]}"
		fi
	fi

	if ((${#missing[@]})); then
		if [[ $DRY_RUN -eq 1 ]]; then
			log "dry-run: would install apt packages: ${missing[*]}"
		else
			apt_update_once
			sudo apt install -y "${missing[@]}"
		fi
	elif ((${#missing_no_recommends[@]} == 0)); then
		log "apt packages already installed"
	fi

	if ((${#reconcile[@]})); then
		if [[ $DRY_RUN -eq 1 ]]; then
			log "dry-run: would install apt package candidates: ${reconcile[*]}"
		else
			apt_update_once
			sudo apt install -y --allow-downgrades "${reconcile[@]}"
		fi
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

	cleanup_obsolete_apt_configuration || true
}

remove_replaced_snaps() {
	local apt_package
	local entry
	local snap_package

	while IFS= read -r entry; do
		apt_package=$(jq -r '.package' <<<"$entry")
		snap_package=$(jq -r '."replaces-snap" // empty' <<<"$entry")
		[[ -n "$snap_package" ]] || continue

		if [[ $DRY_RUN -eq 1 ]]; then
			if snap_is_installed "$snap_package"; then
				log "dry-run: would remove replaced snap package: $snap_package"
			fi
			continue
		fi

		if ! apt_matches_candidate "$apt_package"; then
			error "Refusing to remove $snap_package snap: $apt_package apt candidate is not installed"
		fi

		if snap_is_installed "$snap_package"; then
			log "Removing replaced snap package: $snap_package"
			sudo snap remove "$snap_package"
		fi
	done < <(apt_package_entries)
}

install_snap_packages() {
	local entry
	local package
	local command_name
	local apt_package
	local classic
	local -a install_args

	local snap_entries

	snap_entries=$(package_entries snap)
	if [[ -z "$snap_entries" ]]; then
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
		classic=$(jq -r '.classic // false' <<<"$entry")
		install_args=("$package")

		if [[ "$classic" == "true" ]]; then
			install_args+=("--classic")
		fi

		if [[ $DRY_RUN -eq 1 ]]; then
			if [[ -n "$command_name" ]] && command -v "$command_name" >/dev/null 2>&1; then
				log "$package already installed"
				continue
			fi

			if [[ -n "$apt_package" ]] && apt_has_candidate "$apt_package"; then
				log "dry-run: would install apt fallback for $package: $apt_package"
				continue
			fi

			log "dry-run: would install snap package: ${install_args[*]}"
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

		sudo snap install "${install_args[@]}"
	done <<<"$snap_entries"
}

install_flatpak_packages() {
	local entry
	local flatpak_entries
	local package
	local installed

	flatpak_entries=$(package_entries flatpak)
	if [[ -z "$flatpak_entries" ]]; then
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

	while IFS= read -r entry; do
		package=$(jq -r '.package' <<<"$entry")
		[[ -n "$package" ]] || continue
		if printf '%s\n' "$installed" | grep -qx "$package"; then
			log "$package already installed"
		elif [[ $DRY_RUN -eq 1 ]]; then
			log "dry-run: would install flatpak package: $package"
		else
			flatpak install --user --noninteractive --assumeyes flathub "$package"
		fi
	done <<<"$flatpak_entries"
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
	done < <(selected_hooks)
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
DMI_PRODUCT_FAMILY=$(read_dmi_product_family /sys/class/dmi/id)
require_command apt-cache
require_command awk
require_command sort
require_command uniq

validate_manifest
log_filter_decisions
bootstrap_setup_packages
configure_apt_repositories
install_apt_packages
remove_replaced_snaps
install_snap_packages
install_flatpak_packages
install_mise
run_hooks

echo ""
log "✓"
