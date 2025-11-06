#!/bin/bash

set -e

if ! command -v dropbox &> /dev/null; then
  cd /tmp
  echo "setup/ubuntu/app-dropbox - Fetching latest Dropbox deb URL"
  DROPBOX_DEB_URL=$(curl -s "https://linux.dropbox.com/packages/debian/" | grep -o 'href="dropbox_[0-9][^"]*_amd64\.deb"' | head -1 | sed 's/href="//;s/"//')
  
  if [ -z "$DROPBOX_DEB_URL" ]; then
    echo "setup/ubuntu/app-dropbox - Could not find latest version, using fallback URL"
    DROPBOX_DEB_URL="dropbox_2025.05.20_amd64.deb"
  fi
  
  echo "setup/ubuntu/app-dropbox - Downloading Dropbox deb"
  curl -L "https://linux.dropbox.com/packages/debian/${DROPBOX_DEB_URL}" -o dropbox.deb

  echo "setup/ubuntu/app-dropbox - Installing Dropbox deb"
  sudo apt install -y ./dropbox.deb
  rm dropbox.deb
  cd -
fi

echo -e "setup/ubuntu/app-dropbox - ✓"
