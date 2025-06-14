#!/bin/bash

set -e

# Check if the Sublime Text repository is already added
if [ ! -f /etc/apt/sources.list.d/sublime-text.sources ]; then
  echo "setup/ubuntu/app-sublime-text - Adding sublime-text gpg key"
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null

  echo "setup/ubuntu/app-sublime-text - Adding sublime-text repository"
  echo -e 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.asc' | sudo tee /etc/apt/sources.list.d/sublime-text.sources

  echo "setup/ubuntu/app-sublime-text - Running apt-update"
  sudo apt update
fi

if ! command -v subl &> /dev/null; then
  echo "setup/ubuntu/app-sublime-text - Running apt-install sublime-text"
  sudo apt install -y sublime-text
fi

echo -e "setup/ubuntu/app-sublime-text - ✓"
