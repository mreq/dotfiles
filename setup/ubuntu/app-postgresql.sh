#!/bin/bash

set -e

# Function to check if a user exists
user_exists() {
  id "$1" &>/dev/null
}

# Function to check if a line exists in a file
line_exists_in_file() {
  sudo grep -Fxq "$1" "$2"
}

# Install PostgreSQL if not installed
if ! command -v psql &> /dev/null; then
  echo "setup/ubuntu/app-postgresql - Installing PostgreSQL"
  sudo apt update
  sudo apt install -y postgresql postgresql-client postgresql-contrib
fi

# Check if the 'postgres' user exists
if ! user_exists "postgres"; then
  echo "setup/ubuntu/app-postgresql - postgres user does not exist. Please ensure PostgreSQL installation is correct."
  exit 1
fi

# Create a superuser if not already present
SUPERUSER="petr"
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$SUPERUSER'" | grep -q 1; then
  echo "setup/ubuntu/app-postgresql - Creating superuser '$SUPERUSER'..."
  sudo -u postgres createuser -s -i -d -r -l -w "$SUPERUSER"
fi

# Locate the pg_hba.conf file
PG_HBA_FILE=$(sudo -u postgres psql -tAc "SHOW hba_file;")

if [ -z "$PG_HBA_FILE" ]; then
  echo "setup/ubuntu/app-postgresql - Could not locate pg_hba.conf file. Exiting..."
  exit 1
fi

# Update pg_hba.conf to allow password authentication
PASSWORD_AUTH_LINE="host    all             all             localhost               password"
if ! line_exists_in_file "$PASSWORD_AUTH_LINE" "$PG_HBA_FILE"; then
  echo "setup/ubuntu/app-postgresql - Updating pg_hba.conf to allow password authentication..."
  sudo sed -i "/# IPv4 local connections:/a $PASSWORD_AUTH_LINE" "$PG_HBA_FILE"
  echo "setup/ubuntu/app-postgresql - Updated pg_hba.conf. Restarting PostgreSQL..."
  sudo systemctl restart postgresql
fi

echo "setup/ubuntu/app-postgresql - ✓"
