#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

install_extensions() {
	local ext_dir="$1"
	for ext in "$SCRIPT_DIR"/*/; do
		local name
		name="$(basename "$ext")"
		local target="$ext_dir/$name"
		if ! test -h "$target" || ! test -e "$target"; then
			echo "Installing extension $name -> $target"
			rm -rf "$target" && ln -s "$ext" "$target"
		fi
	done
}

if [[ -d ~/.vscode/extensions ]]; then
	install_extensions ~/.vscode/extensions
fi

if [[ -d ~/.cursor/extensions ]]; then
	install_extensions ~/.cursor/extensions
fi
