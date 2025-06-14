#!/bin/bash

set -e

setup_thunderbird() {
  echo "setup/ubuntu/app-thunderbird - Adding ppa"
  sudo add-apt-repository -y ppa:mozillateam/ppa

  echo "setup/ubuntu/app-thunderbird - Setting apt priority"
  echo '
  Package: *
  Pin: release o=LP-PPA-mozillateam
  Pin-Priority: 1001

  Package: thunderbird
  Pin: version 2:1snap*
  Pin-Priority: -1
  ' | sudo tee /etc/apt/preferences.d/thunderbird

  echo "setup/ubuntu/app-thunderbird - Installing from apt"
  sudo apt update
  sudo apt install -y thunderbird
}

# Check if thunderbird is installed as snap
if ! command -v thunderbird &> /dev/null; then
  setup_thunderbird
else
  if which thunderbird | grep -q 'snap'; then
    echo "setup/ubuntu/app-thunderbird - Removing snap"
    sudo snap remove thunderbird
    setup_thunderbird
  fi
fi

echo "setup/ubuntu/app-thunderbird - ✓"
