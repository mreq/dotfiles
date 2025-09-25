#!/bin/bash

set -e

if ! command -v gitui &>/dev/null; then
  echo -e "setup/ubuntu/app-gitui - Installing gitui"

  (
    cd /tmp

    wget -O gitui.tar.gz "https://github.com/gitui-org/gitui/releases/download/v0.27.0/gitui-linux-x86_64.tar.gz"
    tar -xf gitui.tar.gz

    sudo install gitui /usr/local/bin/gitui
    rm -rf gitui.tar.gz
    rm -rf gitui
  )
fi

echo -e "setup/ubuntu/app-gitui - ✓"
