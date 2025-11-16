#!/bin/bash

set -e

# Check if Flatpak version is installed
if flatpak list | grep -q "com.slack.Slack"; then
  echo "setup/ubuntu/app-slack - Flatpak version already installed"
elif ! command -v slack &> /dev/null; then
  echo "setup/ubuntu/app-slack - Installing slack snap"
  sudo snap install slack
fi

echo "setup/ubuntu/app-slack - ✓"
