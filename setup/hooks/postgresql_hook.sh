#!/bin/bash

set -euo pipefail

SUPERUSER=${USER:?}

log() {
	echo "setup/hooks/postgresql_hook - $*"
}

if ! id postgres >/dev/null 2>&1; then
	log "postgres user is missing; PostgreSQL installation may have failed"
	exit 1
fi

if command -v systemctl >/dev/null 2>&1 && ! systemctl is-active --quiet postgresql; then
	log "Starting PostgreSQL"
	sudo systemctl enable --now postgresql
fi

if sudo -u postgres psql --tuples-only --no-align --set=rolname="$SUPERUSER" \
	-c "SELECT 1 FROM pg_roles WHERE rolname = :'rolname';" | grep -Fxq 1; then
	log "PostgreSQL role already exists: $SUPERUSER"
	exit 0
fi

log "Creating PostgreSQL superuser: $SUPERUSER"
sudo -u postgres createuser -s -i -d -r -l "$SUPERUSER"
