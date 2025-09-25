#!/bin/bash

set -e

if ! command -v freelens &>/dev/null; then
  echo -e "setup/ubuntu/app-freelens - Installing freelens"

  (
    cd /tmp

    wget -O Freelens-1.4.0-linux-amd64.deb "https://github.com/freelensapp/freelens/releases/download/v1.4.0/Freelens-1.4.0-linux-amd64.deb"
    sudo dpkg -i Freelens-1.4.0-linux-amd64.deb

    rm -rf Freelens-1.4.0-linux-amd64.deb
  )
fi

echo -e "setup/ubuntu/app-freelens - ✓"
