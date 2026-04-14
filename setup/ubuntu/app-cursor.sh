#!/bin/bash

set -e

DOWNLOAD_URL="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/3.1"

if ! command -v cursor &>/dev/null; then
	echo "setup/ubuntu/app-cursor - Installing Cursor"

	(
		cd /tmp
		curl -L "$DOWNLOAD_URL" -o cursor-latest.deb
		sudo dpkg -i cursor-latest.deb || sudo apt-get install -f -y
		rm -f cursor-latest.deb
	)
fi

echo "setup/ubuntu/app-cursor - ✓"
