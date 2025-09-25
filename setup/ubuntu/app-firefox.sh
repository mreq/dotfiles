#!/bin/bash

set -e

setup_firefox() {
  echo "setup/ubuntu/app-firefox - Adding ppa"
  sudo add-apt-repository -y ppa:mozillateam/ppa

  echo "setup/ubuntu/app-firefox - Setting apt priority"
  echo '
  Package: *
  Pin: release o=LP-PPA-mozillateam
  Pin-Priority: 1001

  Package: firefox
  Pin: version 2:1snap*
  Pin-Priority: -1
  ' | sudo tee /etc/apt/preferences.d/firefox

  echo "setup/ubuntu/app-firefox - Installing from apt"
  sudo apt update
  sudo apt install -y firefox
}

# Check if firefox is installed as snap
if ! command -v firefox &> /dev/null; then
  setup_firefox
else
  if which firefox | grep -q 'snap'; then
    echo "setup/ubuntu/app-firefox - Removing snap"
    sudo snap remove firefox
    setup_firefox
  fi
fi

echo "setup/ubuntu/app-firefox - ✓"
