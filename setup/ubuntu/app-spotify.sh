#!/bin/bash

set -e

# Check if Flatpak version is installed
if flatpak list | grep -q "com.spotify.Client"; then
  echo "setup/ubuntu/app-spotify - Flatpak version already installed"
elif ! command -v spotify &> /dev/null; then
  if [ ! -f /etc/apt/sources.list.d/spotify.list ]; then
    echo "setup/ubuntu/app-spotify - Adding spotify gpg key"
    curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg

    echo "setup/ubuntu/app-spotify - Adding spotify repository"
    echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

    echo "setup/ubuntu/app-spotify - Running apt-update"
    sudo apt update
  fi

  echo "setup/ubuntu/app-spotify - Running apt install spotify-client"
  sudo apt install -y spotify-client
fi

echo "setup/ubuntu/app-spotify - ✓"
