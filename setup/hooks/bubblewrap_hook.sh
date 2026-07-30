#!/bin/bash

set -euo pipefail

APPARMOR_PROFILE=/etc/apparmor.d/usr.bin.bwrap

log() {
	echo "setup/hooks/bubblewrap_hook - $*"
}

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		log "ERROR: Missing required command: $1" >&2
		exit 1
	fi
}

require_command apparmor_parser
require_command bwrap
require_command cmp

tmp_profile=$(mktemp)
trap 'rm -f "$tmp_profile"' EXIT

cat >"$tmp_profile" <<'EOF'
abi <abi/4.0>,
include <tunables/global>

profile bwrap /usr/bin/bwrap flags=(unconfined) {
  userns,

  include if exists <local/bwrap>
}
EOF

profile_changed=0

if [[ -f "$APPARMOR_PROFILE" ]] && cmp -s "$tmp_profile" "$APPARMOR_PROFILE"; then
	log "$APPARMOR_PROFILE is current"
else
	log "Installing $APPARMOR_PROFILE"
	sudo install -D -m 0644 "$tmp_profile" "$APPARMOR_PROFILE"
	profile_changed=1
fi

if [[ $profile_changed -eq 1 ]]; then
	log "Loading $APPARMOR_PROFILE"
	sudo apparmor_parser -r "$APPARMOR_PROFILE"
fi

log "Validating Bubblewrap"
if ! bwrap --ro-bind / / true; then
	log "Reloading $APPARMOR_PROFILE after failed validation"
	sudo apparmor_parser -r "$APPARMOR_PROFILE"
	bwrap --ro-bind / / true
fi
