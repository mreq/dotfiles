#!/bin/bash

set -e

if ! command -v dropbox &> /dev/null; then
  cd /tmp
  echo "setup/ubuntu/app-dropbox - Downloading Dropbox installer"
  wget -O dropbox.py "https://www.dropbox.com/download?dl=packages/dropbox.py"

  echo "setup/ubuntu/app-dropbox - Installing Dropbox"
  python3 dropbox.py install -i
  rm dropbox.py
  cd -
fi

echo -e "setup/ubuntu/app-dropbox - ✓"
