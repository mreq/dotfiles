#!/bin/bash

set -e

# Check if Slack is already installed
if ! command -v slack &> /dev/null; then
  echo "setup/ubuntu/app-slack - Installing slack snap"
  sudo snap install slack
fi

echo "setup/ubuntu/app-slack - ✓"
