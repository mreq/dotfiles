#!/bin/bash

set -e

if ! command -v flatpak &> /dev/null; then
  echo "setup/ubuntu/app-flatpak - Installing flatpak"
  sudo apt install -y flatpak
fi

# Add Flathub repository if not already added
if ! flatpak remote-list | grep -q flathub; then
  echo "setup/ubuntu/app-flatpak - Adding Flathub repository"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# Install all Flatpak packages
echo "setup/ubuntu/app-flatpak - Installing Flatpak packages"
PACKAGES=$(jq -r '.packages[].packages[]' ~/.dotfiles/flatpak/packages.json)
for package in $PACKAGES; do
  if ! flatpak list | grep -q "$package"; then
    echo "setup/ubuntu/app-flatpak - Installing $package"
    flatpak install -y flathub "$package" || echo "setup/ubuntu/app-flatpak - Warning: Failed to install $package"
  else
    echo "setup/ubuntu/app-flatpak - $package already installed"
  fi
done

echo "setup/ubuntu/app-flatpak - ✓"

