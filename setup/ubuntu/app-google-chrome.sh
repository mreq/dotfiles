#!/bin/bash

set -e

# Check if Flatpak version is installed
if flatpak list | grep -q "com.google.Chrome"; then
  echo "setup/ubuntu/app-google-chrome - Flatpak version already installed"
  echo "setup/ubuntu/app-google-chrome - Setting up Google Chrome as default browser"
  xdg-settings set default-web-browser com.google.Chrome.desktop
elif ! command -v google-chrome &> /dev/null; then
  cd /tmp
  echo "setup/ubuntu/app-google-chrome - Downloading Google Chrome"
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

  echo "setup/ubuntu/app-google-chrome - Installing Google Chrome deb"
  sudo apt install -y ./google-chrome-stable_current_amd64.deb
  rm google-chrome-stable_current_amd64.deb

  echo "setup/ubuntu/app-google-chrome - Setting up Google Chrome as default browser"
  xdg-settings set default-web-browser google-chrome.desktop
  cd -
fi

echo -e "setup/ubuntu/app-google-chrome - ✓"
