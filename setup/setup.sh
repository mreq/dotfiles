#!/bin/bash

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PACKAGES_JSON="$SCRIPT_DIR/packages.json"

(
	cd "$SCRIPT_DIR" || exit 1

	echo "setup/setup-applications - Running all app installers"
	echo ""

	for file in ./ubuntu/app-*.sh; do
		# shellcheck source=/dev/null
		source "$file"
	done

	echo ""
	echo "setup/setup-applications - Installing python packages"

	if command -v jq >/dev/null && command -v pip3 >/dev/null; then
		mapfile -t pip_packages < <(jq -r '.pip[].package' "$PACKAGES_JSON")

		if ((${#pip_packages[@]})); then
			pip3 install "${pip_packages[@]}" --break-system-packages >/dev/null 2>&1 || true
		fi
	else
		echo "setup/setup-applications - Skipping python packages; jq or pip3 is missing"
	fi
)

echo ""
echo "setup/setup-applications - ✓"
