#!/bin/bash

set -e

if ! command -v brightnessctl &> /dev/null; then
  echo "setup/ubuntu/app-brightnessctl - Installing brightnessctl"
  sudo apt update
  sudo apt install -y brightnessctl
fi

# if current user not in video group, add them
if ! groups | grep -q "\bvideo\b"; then
  echo "setup/ubuntu/app-brightnessctl - Adding current user to video group to allow running with sudo..."
  sudo usermod -aG video "$USER"
fi

echo "setup/ubuntu/app-brightnessctl - ✓"
