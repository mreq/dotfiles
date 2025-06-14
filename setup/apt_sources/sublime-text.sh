#!/bin/bash

set -e

# Check if the Sublime Text repository is already added
if [ -f /etc/apt/sources.list.d/sublime-text.sources ]; then
  echo "Sublime Text repository is already set up."
  exit 0
fi

# Download and add the Sublime Text GPG key
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null

# Add the Sublime Text repository to the sources list
echo -e 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.asc' | sudo tee /etc/apt/sources.list.d/sublime-text.sources

# Print a success message
echo "Sublime Text repository has been successfully added!"
