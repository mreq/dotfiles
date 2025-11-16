#!/bin/bash

set -e

(
  cd "$(dirname "$0")" || exit 1

  echo "setup/setup-applications - Running all app installers"
  echo ""
  echo "Note: app-flatpak.sh runs first (alphabetically) to install Flatpak apps"

  for file in ./ubuntu/app-*.sh
  do
    source "$file"
  done

  echo ""
  echo "setup/setup-applications - Installing python requirements"
  pip3 install -r ./python/requirements.txt --break-system-packages > /dev/null 2>&1 || true
)

echo ""
echo "setup/setup-applications - ✓"
